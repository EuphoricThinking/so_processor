global so_emul
section .rodata
align 16
jump: dq procedure1, procedure1, procedure2

section .text
so_emul:
;	push .procedure1
;	push .procedure2
	jmp [rel jump + 16]

procedure1:
	mov rax, 3
	ret

procedure2:
	mov rax, 4
	ret
