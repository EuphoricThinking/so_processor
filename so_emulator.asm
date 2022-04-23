global so_emul

A_POS equ 56

section .rodata
align 16
jump: dq procedure1, procedure1, procedure2

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
	mov rax, 1
	shl rax, 8
;	shl rax, A_POS
	ret

check_steps:
	test rdx, rdx
	jz .no_steps_left

	jmp [rel jump + 16]

.no_steps_left:
	xor rax, rax
	movsx rdx, byte [rel A]
;	shr rdx, 


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

