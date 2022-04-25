global so_emul

%ifndef CORES
%define CORES 1
%endif

; index in state table
A_IND equ 0
D_IND equ 1
X_IND equ 2
Y_IND equ 3
PC_IND equ 4

C_IND equ 6
Z_IND equ 7

; Selectors of the groups of instructions (MOV - XCHG, MOVI - RCR, CLC - STC, JMP - JZ

GROUP_SELECTOR equ 0xC000
SECOND_GROUP equ 0x4000
THIRD_GROUP equ 0x8000

; Constant biases in procedure addresses table (.bss table instructions)
SECOND_GR_ADDR_CONST equ 8
THIRD_GR_ADDR_CONST equ 9
FOURTH_GR_ADDR_CONST equ 15

XCHG_CODE equ 8

; Codes for distinction whether argument is a register, memory address
; or a memory address produced by addition of register values
MEM_ADDR_CODE equ 4
X_Y_PLUS_CODE equ 2
X_Y_BIAS equ 2

SPINLOCK_OWNED equ 1
SPINLOCK_XCHG equ 2      ; mocking acquired spinlock for lack of atomicity in xchg

CLEAR_LEFT_A1 equ 5
CLEAR_RIGHT_AFTER_LEFT equ 13

CLEAR_LEFT_A2 equ 2
CLEAR_RIGHT_A2 equ 11

section .rodata
align 16
instructions: dq MOV, EMPT, OR, EMPT, ADD, SUB, ADC, SBB, \
		 MOVI, \
		 CLC, STC, \
		 XORI, ADDI, CMPI, RCR, JMP, \
		 EMPT, JNC, JC, JNZ, JZ

section .bss
; A D X Y PC C Z
; Filled with zeros memory for cores data sets
align 8
state: resb 8*CORES

alignb 4
spin_lock: resd 1


section .text

; r12 - status of ownership of the spinlock for the current core
; r13 - temporary exchange register for spinlock
; r11 - address of the instruction table
; r10 - the first argument
; r9 - the second argument or imm8
; r8 - temporary; resulting address storage for argument 1-2 evaluation
; rbx - address to jump from the procedure for arguments 1-2 evaluation
; rcx - table address for the current core

so_emul:
    push rbx
    push r12
    push r13

    xor r12, r12 ; Current thread doesn't use spinlock
    mov r13d, 1  ; temporary spinlock flag

	lea r11, [rel instructions]
;	lea rcx, [rel state]

	mov rax, CORES
	cmp rax, 1
	je .single_core

	lea r8, [rel state]
	lea rcx, [r8 + 8*rcx]

	jmp check_steps

.single_core:
	lea rcx, [rel state]

check_steps:
    test r12, r12
    jz .clean_spinlock

    mov dword[rel spin_lock], r13d ; assumed r13d = 0
    mov r13d, 1
    xor r12, r12

.clean_spinlock:
	test rdx, rdx
	jz .no_steps_left

	movzx r10, byte[rcx + PC_IND]
	mov r10w, word[rdi + 2*r10]   ; a value from code - program memory

	dec rdx
	inc byte [rcx + PC_IND]

	cmp r10w, 0xFFFF ; BRK
	je .no_steps_left

	movzx rax, r10w ; a value to operate on

	mov r9w, GROUP_SELECTOR  ; a selector to compare with a value from code
	and r9w, r10w

	test r9w, r9w
	jz .first_group

	cmp r9w, GROUP_SELECTOR
	je .fourth_group

	cmp r9w, SECOND_GROUP
	je .second_group

	cmp r9w, THIRD_GROUP
	je .third_group

	jmp check_steps

.first_group:
    cmp al, XCHG_CODE
    je XCHG

    lea rbx, [rel check_steps.first_r10]

	mov r8, rax                     ; arg1      ; r10
	shl r8w, CLEAR_LEFT_A1          ; clear arg1 from left bits
	shr r8w, CLEAR_RIGHT_AFTER_LEFT ; clear arg1 from right bits

	jmp read_address_of_arg_val

.first_r10:
	mov r10, r8  ; arg1, address

    lea rbx, [rel check_steps.first_r9]

	mov r8, rax  ; arg2     ; r9
	shr r8w, CLEAR_RIGHT_A2  ; nothing before - empty left bits

	jmp read_address_of_arg_val

.first_r9:
	mov r9b, byte[r8]   ; arg2 - insert value, not address

	movzx rax, al

	jmp [r11 + 8*rax]

.second_group:
    lea rbx, [rel check_steps.second_r10]

	mov r8, rax                     ; arg1   ; r10
	shl r8w, CLEAR_LEFT_A1

	shr r8w, CLEAR_RIGHT_AFTER_LEFT

	jmp read_address_of_arg_val

.second_r10:
	mov r10, r8                     ; arg1, address

	mov r9b, al                     ; imm8, value

	shl ax, CLEAR_LEFT_A2
	shr ax, CLEAR_RIGHT_AFTER_LEFT

	jmp [r11 + 8*(rax + SECOND_GR_ADDR_CONST)]

.third_group:
	mov r9, rax
	shr r9, 8
	and r9, 1

	jmp [r11 + 8*(THIRD_GR_ADDR_CONST + r9)]

.fourth_group:
	mov r9b, al  ; imm8

	shl ax, CLEAR_LEFT_A1
	shr ax, CLEAR_RIGHT_AFTER_LEFT

	jmp [r11 + 8*(rax + FOURTH_GR_ADDR_CONST)]

.no_steps_left:
	mov rax, [rcx]

    pop r13
	pop r12
	pop rbx

	ret

;MEM_ADDR_CODE equ 4
;X_Y_PLUS_CODE equ 2
;X_Y_BIAS equ 2
;SPINLOCK_OWNED equ 1
;SPINLOCK_XCHG equ 2
read_address_of_arg_val:
	test r8b, MEM_ADDR_CODE
	jnz .x_y_test

	lea r8, [rcx + r8]  ; register address

    jmp rbx

.x_y_test:
    test r12, r12
    jnz .spinlock_acquired ; we have the previous spinlock
    ; From this section and further, it is known that address from data memory
    ; will be used
.spinlock_wait:
    xchg dword[rel spin_lock], r13d
    test r13d, r13d
    jnz .spinlock_wait

    mov r12, SPINLOCK_OWNED ; indicates that the current core owns spinlock

.spinlock_acquired:
	test r8b, X_Y_PLUS_CODE
	jnz .x_y_plus

    ; value under the address which is the value of register X or Y
	and r8b, 1   ; codes differ at one bit
	movzx r8, byte[rcx + X_Y_BIAS + r8] ; it's uint8_t, unsigned; move x or y to register
	lea r8, [rsi + r8]

    jmp rbx

.x_y_plus:
	and r8b, 1
	movzx r8, byte[rcx + X_Y_BIAS + r8] ; move x or y to register
	add r8b, byte[rcx + D_IND]
	lea r8, [rsi + r8]

    jmp rbx


MOV:
	mov byte[r10], r9b

	jmp check_steps

OR:
	or byte[r10], r9b
	setz byte[rcx + Z_IND]

	jmp check_steps

ADD:
	add byte[r10], r9b
	setz byte[rcx + Z_IND]

	jmp check_steps

SUB:
	sub byte[r10], r9b
	setz byte[rcx + Z_IND]

	jmp check_steps

ADC:
	test byte[rcx + C_IND], 1
	jnz .set_cf_adc

	clc
	jmp .after_set_adc

.set_cf_adc:
	stc

.after_set_adc:
	adc byte[r10], r9b
	setc byte[rcx + C_IND]
	setz byte[rcx + Z_IND]

	jmp check_steps

SBB:
	test byte[rcx + C_IND], 1
	jnz .set_cf_sbb

	clc
	jmp .after_set_sbb

.set_cf_sbb:
	stc

.after_set_sbb:
	sbb byte[r10], r9b
	setc byte[rcx + C_IND]
	setz byte[rcx + Z_IND]

	jmp check_steps

MOVI:
	mov byte[r10], r9b

	jmp check_steps

XORI:
	xor byte[r10], r9b
	setz byte[rcx + Z_IND]

	jmp check_steps

ADDI:
	add byte[r10], r9b
	setz byte[rcx + Z_IND]

	jmp check_steps

; Empty procedure for inorrect codes and filling the empty indexes in the instruction table
EMPT:
	jmp check_steps

CMPI:
	cmp byte[r10], r9b
	setc byte[rcx + C_IND]
	setz byte[rcx + Z_IND]

	jmp check_steps

RCR:
	test byte[rcx + C_IND], 1
	jnz .set_cf_rcr

	clc
	jmp .after_set_rcr

.set_cf_rcr:
	stc

.after_set_rcr:
	rcr byte[r10], 1
	setc byte[rcx + C_IND]

	jmp check_steps

CLC:
	mov byte[rcx + C_IND], 0

	jmp check_steps

STC:
	mov byte[rcx + C_IND], 1

	jmp check_steps

JMP:
	add byte[rcx + PC_IND], r9b

	jmp check_steps

JNC:
	mov r8b, byte[rcx + C_IND]
	test r8b, r8b
	jnz check_steps

	add byte[rcx + PC_IND], r9b

	jmp check_steps

JC:
	mov r8b, byte[rcx + C_IND]
	test r8b, r8b
	jz check_steps

	add byte[rcx + PC_IND], r9b

	jmp check_steps

JNZ:
	mov r8b, byte[rcx + Z_IND]
	test r8b, r8b
	jnz check_steps

	add byte[rcx + PC_IND], r9b

	jmp check_steps

JZ:
	mov r8b, byte[rcx + Z_IND]
	test r8b, r8b
	jz check_steps

	add byte[rcx + PC_IND], r9b

	jmp check_steps

BRK:
	jmp check_steps

;MEM_ADDR_CODE equ 4
;X_Y_PLUS_CODE equ 2
;X_Y_BIAS equ 2
;SPINLOCK_OWNED equ 1
;SPINLOCK_XCHG equ 2
XCHG:

    mov r10, rax                ; arg1
    shl r10w, CLEAR_LEFT_A1     ; clear arg1 from left bits
    shr r10w, CLEAR_RIGHT_AFTER_LEFT

    mov r9, rax                 ; arg2     ; r9
    shr r9w, CLEAR_RIGHT_A2

    ; If the arg1 bit which is set for codes of arguments as addresses
    ; is not set, xchg is non-atomic
    test r10b, MEM_ADDR_CODE
    jz .non_atomic

    ; Reversely, the mentioned bit should not be set for arg2
    test r9b, MEM_ADDR_CODE
    jnz .non_atomic

    jmp .get_args

.non_atomic:
    ; Mocks spinlock acquirement; since read_address_of_arg_val test only for
    ; non-zero values, we can use different indicator values for different
    ; purposes, leaving zero for unacquired spinlocks
    mov r12, SPINLOCK_XCHG

.get_args:
    mov r8, r10
    lea rbx, [rel XCHG.xchg_r10]
    jmp read_address_of_arg_val ; spinlock is acquired in this function or ignored due to set r12

.xchg_r10:
    mov r10, r8

    mov r8, r9
    lea rbx, [rel XCHG.xchg_r9]
    jmp read_address_of_arg_val ; spinlock is acquired in this function or ignored due to set r12

.xchg_r9:

    mov r9b, byte[r8]       ; r8 stores address; r9 is a storage for value
    mov al, byte[r10]       ; r10 stores address; al is a storage for value

    ; Addresses in registers don't change, only values
    mov byte[r10], r9b      ; value at r8  -> value at r10
    mov byte[r8], al        ; value at r10 -> value at r8

    cmp r12, SPINLOCK_XCHG
    jne check_steps

    ; Clears the mocked flag
    xor r12, r12

	jmp check_steps
