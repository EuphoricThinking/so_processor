global so_emul

%define modulo 0xF &

%define last_bit 1 &

%ifndef CORES
%define CORES 1
%endif

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

C_IND equ 6  ; previous 5
Z_IND equ 7  ; previous 7

GROUP_SELECTOR equ 0xC000
SECOND_GROUP equ 0x4000
THIRD_GROUP equ 0x8000

SECOND_GR_ADDR_CONST equ 9
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
state: resb 8*CORES
					;SETcc instructions!

testtab: resb 4
;cur_proc: resq 1

section .data
cur_proc: dq 1

section .text

so_emul:
	push rbx
	lea rbx, [rel instructions]
	lea r11, [rel state]

check_steps:
	test rdx, rdx
	jz .no_steps_left

	movzx r10, byte[rel state + 8*rcx + PC_IND]
	mov r10w, word[rdi + 2*r10]   ; a value from code

	dec rdx
	inc byte [rel state + PC_IND]

	cmp r10w, 0xFFFF
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
	lea r10, [rel check_steps.first_r10]
	mov qword[rel cur_proc], r10

	mov r8, rax ; arg1      ; r10
	shl r8w, CLEAR_LEFT_A1   ; clear arg2 from left bits
	shr r8w, CLEAR_RIGHT_AFTER_LEFT

	jmp .read_address_of_arg_val

.first_r10:
	mov r10, r8  ; arg1, address

	lea r9, [rel check_steps.first_r9]
	mov qword[rel cur_proc], r9

	mov r8, rax  ; arg2     ; r9
	shr r8w, CLEAR_RIGHT_A2  ; nothing before

	jmp .read_address_of_arg_val

.first_r9:
	mov r9b, byte[r8]   ; arg2 - insert value, not address

	movsx rax, al
;	ret
	jmp [rbx + 8*rax]

.second_group:
	lea r10, [rel check_steps.second_r10]
	mov qword[rel cur_proc], r10

	mov r8, rax  ; arg1   ; r10
	shl r8w, CLEAR_LEFT_A1

	shr r8w, CLEAR_RIGHT_AFTER_LEFT

	jmp .read_address_of_arg_val

.second_r10:
	mov r10, r8  ; arg1, address

	mov r9b, al  ; imm8, value

	shl ax, CLEAR_LEFT_A2
	shr ax, CLEAR_RIGHT_AFTER_LEFT

	jmp [rbx + 8*(rax + SECOND_GR_ADDR_CONST)]

.third_group:
	mov r9, rax
	shr r9, 8
	and r9, 1

	jmp [rbx + 8*(THIRD_GR_ADDR_CONST + r9)]

.fourth_group:
	mov r9b, al  ; imm8

	shl ax, CLEAR_LEFT_A1
	shr ax, CLEAR_RIGHT_AFTER_LEFT

	jmp [rbx + 8*(rax + FOURTH_GR_ADDR_CONST)]

.read_address_of_arg_val:
	test r8b, 4
	jnz .x_y_test

	lea r8, [r11 + r8]
	jmp [rel cur_proc]

.x_y_test:
	test r8, 2
	jnz .x_y_plus

	and r8, 1
	movzx r8, byte[r11 + 2 + r8] ; it's uint8_t, unsigned
	lea r8, [rsi + r8]
	jmp [rel cur_proc]

.x_y_plus:
	and r8, 1
	movzx r8, byte[r11 + 2 + r8]
	add r8b, byte[r11 + D_IND]
	lea r8, [rsi + r8]
	jmp [rel cur_proc]

.no_steps_left:
;	mov byte [rel state + C_IND], 1
;	mov byte [rel state + Z_IND], 1
	mov rax, [r11]
	pop rbx

	ret

procedure1:
	mov rax, 3
	jmp check_steps

procedure2:
	mov rax, 4
	jmp check_steps

MOV:
	mov byte[r10], r9b

	jmp check_steps

OR:
	or byte[r10], r9b
	setz byte[r11 + Z_IND]

	jmp check_steps

ADD:
	add byte[r10], r9b
	setz byte[r11 + Z_IND]

	jmp check_steps

SUB:
	sub byte[r10], r9b
	setz byte[r11 + Z_IND]

	jmp check_steps

ADC:
	test byte[r11 + C_IND], 1
	jnz .set_cf_adc

	clc
	jmp .after_set_adc

.set_cf_adc:
	stc

.after_set_adc:
	adc byte[r10], r9b
	setc byte[r11 + C_IND]
	setz byte[r11 + Z_IND]

	jmp check_steps

SBB:
	test byte[r11 + C_IND], 1
	jnz .set_cf_sbb

	clc
	jmp .after_set_sbb

.set_cf_sbb:
	stc

.after_set_sbb:
	sbb byte[r10], r9b
	setc byte[r11 + C_IND]
	setz byte[r11 + Z_IND]

	jmp check_steps

MOVI:
	mov byte[r10], r9b

	jmp check_steps

XORI:
	xor byte[r10], r9b
	setz byte[r11 + Z_IND]

	jmp check_steps

ADDI:
	add byte[r10], r9b
	setz byte[r11 + Z_IND]

	jmp check_steps

EMPT:
	jmp check_steps

CMPI:
	cmp byte[r10], r9b
	setc byte[r11 + Z_IND]
	setz byte[r11 + C_IND]

	jmp check_steps

RCR:
	test byte[r11 + C_IND], 1
	jnz .set_cf_rcr

	clc
	jmp .after_set_rcr

.set_cf_rcr:
	stc

.after_set_rcr:
	rcr byte[r10], 1
	setc byte[r11 + C_IND]

	jmp check_steps

CLC:
	mov byte[r11 + C_IND], 0

	jmp check_steps

STC:
	mov byte[r11 + C_IND], 1

	jmp check_steps

JMP:
	add byte[r11 + PC_IND], r9b

	jmp check_steps

JNC:
	mov r8b, byte[r11 + C_IND]
	test r8b, r8b
	jnz check_steps

	add byte[r11 + PC_IND], r9b

	jmp check_steps

JC:
	mov r8b, byte[r11 + C_IND]
	test r8b, r8b
	jz check_steps

	add byte[r11 + PC_IND], r9b

	jmp check_steps

JNZ:
	mov r8b, byte[r11 + Z_IND]
	test r8b, r8b
	jnz check_steps

	add byte[r11 + PC_IND], r9b

	jmp check_steps

JZ:
	mov r8b, byte[r11 + Z_IND]
	test r8b, r8b
	jz check_steps

	add byte[r11 + PC_IND], r9b

	jmp check_steps

BRK:
	jmp check_steps

XCHG:
	jmp check_steps
