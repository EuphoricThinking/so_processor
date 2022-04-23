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

section .text

so_emul:
;	mov rax, 1
;	mov r9, 8
;	lea r10, [rax + r9]
;	mov rax, r10
;	ret
;	jmp [r10]
	mov r9, [rdi]
	cmp r9w, 0x0002
	jne check_steps
	mov rax, 17
	ret

check_steps:
	test rdx, rdx
	jz .no_steps_left

	cmp di, 0xFFFF
	je .no_steps_left

	movzx rax, di
	mov rax, 18
	ret
	dec rdx

	mov r9w, GROUP_SELECTOR
	and r9w, di

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
;	jmp [rel instructions + 8*rax]
	jmp [rel instructions + 72]

.second_group:
	mov ax, di

.third_group:
	mov ax, di

.fourth_group:
	mov ax, di


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
	mov rax, 2
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
