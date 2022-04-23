global so_emul

so_emul:
	push .procedure1
	push .procedure2
	call qword [rsp + 8]

.procedure1:
	mov rax, 3
	sub rsp, 16
	ret

.procedure2:
	mov rax, 4
	sub rsp, 16
	ret
