global so_emul

A_POS equ 56
D_POS equ 48
X_POS equ 40
Y_POS equ 32
PC_POS equ 24
; 16 is empty
C_POS equ 8
Z_POS equ 0 ; nothing is needed

section .rodata
align 16
jump: dq procedure1, procedure1, procedure2
instructions: dq MOV, EMPT, OR, EMPT, ADD, SUB, ADC, SBB, XCHG, MOVI, CLC, STC, XORI, ADDI, CMPI, RCR, JMP, EMPT, JNC, JC, JNZ, JZ

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

check_steps:
	test rdx, rdx
;	jz .no_steps_left

;	jmp [rel jump + 16]

.no_steps_left:
	mov byte [rel C], 1
	mov byte [rel Z], 1
;	movsx rax, byte [rel A]
;	ret

	xor rax, rax
	movsx rdx, byte [rel A]
;	mov rax, rdx
;	ret
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

procedure1:
	mov rax, 3
	jmp check_steps

procedure2:
	mov rax, 4
	jmp check_steps

MOV:
	mov rax, 0
	jmp check_steps

OR:
	mov rax, 2
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
