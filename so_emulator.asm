global so_emul
section .data
align 16
jump: dq procedure1, procedure2

section .text
so_emul:
;	push .procedure1
;	push .procedure2
	jmp [rel jump]

procedure1:
	mov rax, 3
	ret

procedure2:
	mov rax, 4
	ret
