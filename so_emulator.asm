global so_emul
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
	jmp [rel jump + 16]

procedure1:
	mov rax, 3
	ret

procedure2:
	mov rax, 4
	ret
