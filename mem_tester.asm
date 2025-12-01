	org 0x7c00
	bits 16

	;; Definição de Constantes Simbólicas
	LF				EQU	10
	CR				EQU	13
	SET_VIDEO_MODE			EQU	0x00
	VIDEO_MODE_80_25_16C		EQU	0x03

	;; IVT (Interrupt Vector Table) Vetor de Interrupção (1KB)
	IVT_START			EQU	0x0000
	IVT_END				EQU	0X03ff

	;; (BDA - BIOS Data Area) Área de Dados do BIOS (256 Bytes)
	BDA_START			EQU	0x0400
	BDA_END				EQU	0X04ff

	;; Região de Memória Livre de Endereços Mais Baixos (30KB~) - Primeira Região de Teste
	LOW_FREE_MEM_START 		EQU	0x0500
	LOW_FREE_MEM_END		EQU	0x7bff

	;; Região de Memória do Programa Testador (512 Bytes)
	PROG_START			EQU	0x7c00
	PROG_END			EQU	0x7dff

	;; Região de Memória Livre de Endereços Mais Altos (510KB~) - Segundo Região de Teste
	HIGH_FREE_MEM_START		EQU	0x7e00
	HIGH_FREE_MEM_END_LOW		EQU	0xffff

	BIT_20_HIGH_FREE_MEM_START	EQU	0x10000
	BIT_20_HIGH_FREE_MEM_END	EQU	0X7ffff

	;; Endereços acima de 0x7FFFF são todos reservados para BIOS e Vídeo

	;; Constantes de Controle
	STR_ADDR_SIZE			EQU	5
	
start:
	xor ax, ax
	mov ds, ax
	mov es, ax
	
	mov ax, HIGH_FREE_MEM_END_LOW
	mov ss, ax 
	mov sp, ss
	
.set_video:	
	call set_video_mode

.show_mem_layout:
	call display_mem_layout

	mov dh, 7
	mov dl, 0
	mov bh, 0
	call set_cursor_position
	
	;; mov bx, exit
	;; call print_string
	
.animation:
	mov dh, 0
	mov dl, 1
	
.loop_animation:
	call set_cursor_position
	call display_progress_bar
	inc dh
	cmp dh, 6
	je .mem_testing_16_bit
	jmp .loop_animation

.mem_testing_16_bit:
	mov si, LOW_FREE_MEM_START
	mov di, LOW_FREE_MEM_END
	call mem_test

	mov ax, LOW_FREE_MEM_END
	mov ss, ax 
	mov sp, ss

	mov si, HIGH_FREE_MEM_START
	mov di, HIGH_FREE_MEM_END_LOW
	call mem_test

.mem_testing_20_bit:

.init:
	mov cl, 7
	mov dx, 0x1000
	mov ax, dx
.loop:
	mov ds, ax
	xor si, si
	mov di, 0xffff
	call mem_test
	
	add dx, 0x1000
	mov ax, dx
	dec cl
	cmp cl, 0
	je .exit_msg
	jmp .loop

.exit_msg:
	mov dh, 7
	mov dl, 0
	call set_cursor_position
	xor ax, ax
	mov ds, ax
	mov al, [status_mem_error]
	cmp al, 1
	je .error
.ok:
	mov bx, msg_mem_ok
	call print_string
	jmp .end

.error:
	mov bx, msg_mem_error
	call print_string
.end:
	jmp $
	
	;; Rotina para imprimir a barra de progresso do teste
	;; DEPENDÊNCIA: Utilizar set_cursor_position para dizer onde o cursor está
display_progress_bar:

.init:
	push dx
	mov cl, 8
.loop:
	cmp cl, 0
	je .loop_end
	
	mov bx, 18
	call delay
	
	mov ah, 0x0e
	mov al, "-"
	int 0x10

	dec cl
	jmp .loop

.loop_end:
	pop dx
	ret

	;; Rotina de Delay
	;; (BX) - Deve conter a quantidade de ticks (18 ticks ~= 1 segundo)
delay:
	push cx
	mov ah, 0x00
	int 0x1a
	mov si, dx

.wait_loop:
	mov ah, 00h
	int 0x1a
	sub dx, si
	cmp dx, bx
	jb .wait_loop
	pop cx
	ret
		
	;; Rotina que realiza o teste de memória
	;; (SI) - Deve apontar para endereço inicial
	;; (DI) - Deve apontar para endereço final
mem_test:	

.testing_aa:
	mov al, 0xAA
	mov [si], al
	cmp [si], al
	je .testing_55
	call .mem_error

.testing_55:
	mov al, 0x55
	mov [si], al
	cmp [si], al
	je .loop
	call .mem_error
	
.loop:
	cmp si, di
	je .mem_test_end
	inc si
	jmp .testing_aa

.mem_test_end:
	ret

.mem_error:
	mov es:[status_mem_error], 1
	ret
	
	;; Rotina que exibe o layout de memória
display_mem_layout:	
	mov ch, 5
	mov si, addr1
	
.print_layout_pt1:
	mov bx, show_status
	call print_string

	mov ah, 0x0e
	mov al, " "
	int 0x10

	mov dx, [si]
	call print_hex
	
	mov bx, space_between_addr
	call print_string

	add si, 2
	mov dx, [si]
	dec dx
	call print_hex
	
	call print_line_break

	dec ch
	cmp ch, 0
	jne .print_layout_pt1

.print_layout_pt2:
	
.print:	
	mov bx, show_status
	call print_string
	
	mov bx, str_addr1
	call print_addr

	mov bx, space_between_addr
	call print_string

	mov bx, str_addr2
	call print_addr

	call print_line_break

.mem_layout_end:
	ret

	;; Rotina para exibir um endereço em formato de string
	;; (BX) - O endereço da string do tipo endereço (str_addr)
print_addr:
	
.init_values:
	mov cl, STR_ADDR_SIZE

.print_addr_mask:
	mov ah, 0x0e
	mov al, "0"
	int 0x10
	mov al, "x"
	int 0x10
.loop:	
	mov al, [bx]
	int 0x10
	inc bx
	
	dec cl
	cmp cl, 0
	jne .loop
	
.loop_fim:
	ret
	
	;; Rotina para imprimir quebra de linha [ LF - Line Feed (10), CR - Carriage Return (13) ]
print_line_break:
	mov ah, 0x0e
	mov al, LF
	int 0x10
	mov al, CR
	int 0x10
	ret

	;; Interrupt 10H - Video (AH = 02H - Set Cursor Position)
	;; (DH) - Row (zero based)
	;; (DL) - Column (zero based)
	;; (BH) - Page number (zero based)
set_cursor_position:
	mov ah, 0x02
	mov bh, 0
	int 0x10
	ret

	;; Interrupt 10H - Video
	;; (AH = 00H - Set Mode)
	;; (AL) - Requested video mode
set_video_mode:
	mov ah, SET_VIDEO_MODE
	mov al, VIDEO_MODE_80_25_16C
	int 0x10
	ret

	;; Rotina para impressão de uma string na tela em modo TTY (Teletype)
	;; (BX) - Deve conter o endereço inicial da string
print_string:
	push bx
	mov ah, 0x0e
.print:
	mov al, [bx]
	cmp al, 0
	je .print_end
	int 0x10
	inc bx
	jmp .print
.print_end:
	pop bx
	ret

	;; Rotina para imprimr um valor hexadecimal com máscara (0x0000)
	;; (DX) - Deve conter o valor hexadecimal a ser impresso
print_hex:
	
.first_nibble:
	mov al, dh
	shr al, 4
	mov bx, hex_out
	add bx, 2
	call .compare
	
.second_nibble:
	mov al, dh
	and al, 0b00001111
	mov bx, hex_out
	add bx, 3
	call .compare
	
.third_nibble:
	mov al, dl
	shr al, 4
	mov bx, hex_out
	add bx, 4
	call .compare
	
.fourth_nibble:
	mov al, dl
	and al, 0b00001111
	mov bx, hex_out
	add bx, 5
	call .compare
	
	mov bx, hex_out
	call print_string

	;; Zerar a máscara hex_out (0x0000) com .zero_fill
	mov cl, 4
	mov bx, hex_out + 2
	
.zero_fill:
	mov [bx], "0"
	inc bx
	dec cl
	cmp cl, 0
	jne .zero_fill
	ret
	
.compare:
	pusha
	cmp al, 9
	jle .number
	
.letter:
	add al, 55
	mov [bx], al
	jmp .compare_end
	
.number:
	add al, 48
	mov [bx], al
	
.compare_end:
	popa
	ret

	;; Variáveis Globais

	;; Variáveis de Controle
status_mem_error:		db 0

	;; Variáveis de exibição
hex_out: 		db "0x0000", 0
show_status:		db "[", 32, 32, 32, 32, 32, 32, 32, 32, "] ", 0
space_between_addr:	db " - ", 0
msg_mem_ok:		db "OK", 0
msg_mem_error:		db "ERROR", 0

	;; Endereços mais baixos
addr1:			dw IVT_START
addr2:			dw BDA_START
addr3:			dw LOW_FREE_MEM_START
addr4:			dw PROG_START
addr5:			dw HIGH_FREE_MEM_START
addr6:			dw HIGH_FREE_MEM_END_LOW

	;; Endereços mais altos
str_addr1:		db "10000"
str_addr2:		db "7FFFF"

	;; Definição que o tamanho do arquivo de saída gerado pelo montador tenha exatos 512 bytes (tamanho de um setor)
	;; E escrita da assinatura (0xaa55) para que a BIOS reconheça como bootável
	times 510-($-$$) db 0
	dw 0xaa55	
