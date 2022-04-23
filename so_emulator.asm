global so_emul

A_POS equ 56
D_POS equ 48
X_POS equ 40
Y_POS equ 32
PC_POS equ 24
; 16 is empty
C_POS equ 8
Z_POS equ 0 ; nothing is needed

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
align 8
A: resb 1
D: resb 1
X: resb 1
Y: resb 1
PC: resb 1
C: resb 1
Z: resb 1 	;SETcc instructions!

testtab: resb 4

section .text

so_emul:
	lea rcx, [rel instructions]
	lea r9, [rel testtab + 2]
	mov r9b, byte[r9]
	mov byte [rel testtab + 1], r9b
	mov al, byte[rel testtab + 1]
	ret
;	mov rax, 1
;	shl rax, 8
;	shr rax, 8
;	ret
check_steps:
	test rdx, rdx
	jz .no_steps_left

	mov r10, [rdi]   ; a value from code
	cmp r10w, 0xFFFF
	je .no_steps_left

	movzx rax, r10w ; a value to operate on
	dec rdx

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

	jmp after_instruction

;	jmp [rel jump + 16]

.first_group:
	mov r10, rax ; arg1
	shl r10, CLEAR_LEFT_A1   ; divide by 0x100
	shr r10, CLEAR_RIGHT_AFTER_LEFT

	mov r9, rax  ; arg2
	shr r9, CLEAR_RIGHT_A2  ; nothing before

	jmp [rcx + 8*rax]

.second_group:
	mov r10, rax  ; arg1
	shl r10, CLEAR_LEFT_A1
	shr r10, CLEAR_RIGHT_AFTER_LEFT

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

.no_steps_left:
;	mov byte [rel C], 1
;	mov byte [rel Z], 1

	xor rax, rax
	movsx rdx, byte [rel A]

	shl rdx, A_POS
	or rax, rdx

	movsx rdx, byte [rel D]
	shl rdx, D_POS
	or rax, rdx

	movsx rdx, byte [rel X]
	shl rdx, X_POS
	or rax, rdx

	movsx rdx, byte [rel Y]
	shl rdx, Y_POS
	or rax, rdx

	movsx rdx, byte [rel PC]
	shl rdx, PC_POS
	or rax, rdx

	movsx rdx, byte [rel C]
	shl rdx, C_POS
	or rax, rdx

	movsx rdx, byte [rel Z]
	or rax, rdx

	ret

after_instruction:
	add di, 16
	jmp after_instruction

procedure1:
	mov rax, 3
	jmp after_instruction

procedure2:
	mov rax, 4
	jmp after_instruction

MOV:
	mov rax, 22
	ret
	jmp after_instruction

OR:
	mov rax, 93
	ret
	jmp after_instruction

ADD:
	mov rax, 4
	jmp after_instruction

SUB:
	mov rax, 5
	jmp after_instruction

ADC:
	mov rax, 6
	jmp after_instruction

SBB:
	mov rax, 7
	jmp after_instruction

MOVI:
	mov rax, 11
	ret
	jmp after_instruction

XORI:
	jmp after_instruction

ADDI:
	jmp after_instruction

EMPT:
	jmp after_instruction

CMPI:
	jmp after_instruction

RCR:
	jmp after_instruction

CLC:
	jmp after_instruction

STC:
	jmp after_instruction

JMP:
	jmp after_instruction

JNC:
	jmp after_instruction

JC:
	jmp after_instruction

JNZ:
	jmp after_instruction

JZ:
	jmp after_instruction

BRK:
	jmp after_instruction

XCHG:
	jmp after_instruction
