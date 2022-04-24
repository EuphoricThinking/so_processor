global so_emul

%define modulo 0xF &

%define last_bit 1 &

; position in rax
A_POS equ 56
D_POS equ 48
X_POS equ 40
Y_POS equ 32
PC_POS equ 24
; 16 is empty
C_POS equ 8
Z_POS equ 0 ; nothing is needed

; index in state table
A_IND equ 0
D_IND equ 1
X_IND equ 2
Y_IND equ 3
PC_IND equ 4
C_IND equ 5
Z_IND equ 7

GROUP_SELECTOR equ 0xC000
SECOND_GROUP equ 0x4000
THIRD_GROUP equ 0x8000

SECOND_GR_ADDR_CONST equ 1
THIRD_GR_ADDR_CONST equ 10
FOURTH_GR_ADDR_CONST equ 16

CLEAR_LEFT_A1 equ 5
CLEAR_RIGHT_AFTER_LEFT equ 13

CLEAR_LEFT_A2 equ 2
CLEAR_RIGHT_A2 equ 11

section .rodata
align 16
jump: dq procedure1, procedure1, procedure2
instructions: dq MOV, EMPT, OR, EMPT, ADD, SUB, ADC, SBB, XCHG, \
		 MOVI, \
		 CLC, STC, \
		 XORI, ADDI, CMPI, RCR, JMP, \
		 EMPT, JNC, JC, JNZ, JZ

section .bss
align 8		; A D X Y PC C Z
state: resb 7
					;SETcc instructions!

testtab: resb 4
;cur_proc: resq 1

section .data
cur_proc: dq 1

section .text

so_emul:
	lea rcx, [rel instructions]
	lea r11, [rel state]
;	push rbx

;	mov byte[rel testtab], 255
;	add byte[rel testtab], 7
;	mov rax, [rel testtab ]
;	ret

;	inc byte[rel testtab + 2]
;	mov al, byte[rel testtab]
;	ret
;	and byte[rel testtab + 1], 8
;	ret

;	lea r9, [rel testtab + 2]
;	mov r9b, byte[r9]
;	mov byte [rel testtab + 1], r9b
;	mov al, byte[rel testtab + 1]
;	ret

check_steps:
;	jmp .no_steps_left

	test rdx, rdx
	jz .no_steps_left

;	lea r10, [rel state + PC_IND]
;	mov r10, [r10]

	mov r10, [rel state + PC_IND]
	mov r10, [rdi + 2*r10]   ; a value from code
	cmp r10w, 0xFFFF
	je .no_steps_left

	dec rdx
	inc byte [rel state + PC_IND]

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

;	jmp [rel jump + 16]

.first_group:
	lea r10, [rel check_steps.first_r10]
;	jmp r10
;	ret
	mov qword[rel cur_proc], r10
;	jmp [rel cur_proc]

	mov r8, rax ; arg1      ; r10
	shl r8, CLEAR_LEFT_A1   ; clear arg2 from left bits
	shr r8, CLEAR_RIGHT_AFTER_LEFT

	jmp .read_address_of_arg_val

.first_r10:
;	mov rax, 54
;	ret

	mov r10, r8  ; arg1

	movzx rax, byte[r10]
	ret

	lea r9, [rel check_steps.first_r9]
	mov qword[rel cur_proc], r9

	mov r8, rax  ; arg2     ; r9
	shr r8, CLEAR_RIGHT_A2  ; nothing before

	jmp .read_address_of_arg_val

.first_r9:
	mov r9b, byte[r8]   ; arg2 - insert value, not address

;	movzx rax, r9b
;	ret

	jmp [rcx + 8*rax]

.second_group:
	lea r10, [rel check_steps.second_r10]
	mov qword[rel cur_proc], r10

	mov r8, rax  ; arg1   ; r10
	shl r8, CLEAR_LEFT_A1
	shr r8, CLEAR_RIGHT_AFTER_LEFT

	jmp .read_address_of_arg_val

.second_r10:
	mov r10, r8  ; arg1

	mov r9b, al  ; imm8

	shl rax, CLEAR_LEFT_A2
	shr rax, CLEAR_RIGHT_AFTER_LEFT

	jmp [rcx + 8*(rax + SECOND_GR_ADDR_CONST)]
;	mov r9w, al ; imm8

.third_group:
	mov r9, rax
	shr r9, 8
	and r9, 1

	jmp [rcx + THIRD_GR_ADDR_CONST + r9]

.fourth_group:
	mov r9b, al  ; imm8

	shl rax, CLEAR_LEFT_A1
	shr rax, CLEAR_RIGHT_AFTER_LEFT

	jmp [rcx + 8*(rax + FOURTH_GR_ADDR_CONST)]

.read_address_of_arg_val:
	test r8b, 4
	jnz .x_y_test

;	movzx rax, byte[r11]
;	ret

	lea r8, [r11 + r8]
;	ret
	jmp [rel cur_proc]
;	jmp .after_test

.x_y_test:
	test r8, 2
	jnz .x_y_plus

	and r8, 1
	movzx r8, byte[r11 + 2 + r8] ; it's uint8_t, unsigned
	lea r8, [rsi + r8]
	jmp [rel cur_proc]
;	jmp .after_test

.x_y_plus:
;	add r8, [r11 + D_IND]

	and r8, 1
	movzx r8, byte[r11 + 2 + r8]
	add r8, [r11 + D_IND]
	lea r8, [rsi + r8]
	jmp [rel cur_proc]

;.after_test:
;	test rax, 0xC000
;	jnz .first_inner
;	jz .second_inner

.no_steps_left:
;	mov byte [rel C], 1
;	mov byte [rel Z], 1

;	mov byte [rel state + C_IND], 1
;	mov byte [rel state + Z_IND], 1

	xor rax, rax
	movzx rdx, byte [rel state]

	shl rdx, A_POS
	or rax, rdx

	movsx rdx, byte [rel state + D_IND]
	shl rdx, D_POS
	or rax, rdx

	movsx rdx, byte [rel state + X_IND]
	shl rdx, X_POS
	or rax, rdx

	movsx rdx, byte [rel state + Y_IND]
	shl rdx, Y_POS
	or rax, rdx

	movsx rdx, byte [rel state + PC_IND]
	shl rdx, PC_POS
	or rax, rdx

	movsx rdx, byte [rel state + C_IND]
	shl rdx, C_POS
	or rax, rdx

	movsx rdx, byte [rel state + Z_IND]
	or rax, rdx

;	pop rbx
	ret

;after_instruction:
;	add rdi, 16
;	jmp check_steps

procedure1:
	mov rax, 3
	jmp check_steps

procedure2:
	mov rax, 4
	jmp check_steps

MOV:
	mov rax, 22
	ret
	jmp check_steps

OR:
	mov rax, 93
	ret
	jmp check_steps

ADD:
	mov rax, 4
	jmp check_steps

SUB:
	mov rax, 5
	jmp check_steps

ADC:
	mov rax, 6
	jmp check_steps

SBB:
	mov rax, 7
	jmp check_steps

MOVI:
	mov rax, 11
	ret
	jmp check_steps

XORI:
	jmp check_steps

ADDI:
	jmp check_steps

EMPT:
	jmp check_steps

CMPI:
	jmp check_steps

RCR:
	jmp check_steps

CLC:
	jmp check_steps

STC:
	jmp check_steps

JMP:
	jmp check_steps

JNC:
	jmp check_steps

JC:
	jmp check_steps

JNZ:
	jmp check_steps

JZ:
	jmp check_steps

BRK:
	jmp check_steps

XCHG:
	jmp check_steps
