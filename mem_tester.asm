	org 0x7c00
	bits 16

	;; Definição de Constantes Simbólicas
	LF			EQU	10
	CR			EQU	13
	SET_VIDEO_MODE		EQU	0x00
	VIDEO_MODE_80_25_16C	EQU	0x03

	;; IVT (Interrupt Vector Table) Vetor de Interrupção (1KB)
	IVT_START		EQU	0x0000
	IVT_END			EQU	0X03ff

	;; (BDA - BIOS Data Area) Área de Dados do BIOS (256 Bytes)
	BDA_START		EQU	0x0400
	BDA_END			EQU	0X04ff

	;; Região de Memória Livre de Endereços Mais Baixos (30KB) - Primeira Região de Teste
	LOW_FREE_MEM_START 	EQU	0x0500
	LOW_FREE_MEM_END	EQU	0x7bff

	;; Região de Memória do Programa Testador (512 Bytes)
	PROG_START		EQU	0x7c00
	PROG_END		EQU	0x7dff

	;; Região de Memória Livre de Endereços Mais Altos (608KB) - Segundo Região de Teste
	HIGH_FREE_MEM_START	EQU	0x7e00
	HIGH_FREE_MEM_END_LOW	EQU	0xffff
	HIGH_FREE_MEM_END	EQU	0X9fbff

	;; Constantes de Controle
	STR_ADDR_SIZE		EQU	5
	
start:

.set_video:	
	call set_video_mode

.mem_layout:
	call display_mem_layout

.animation:
	mov dh, 0
	mov dl, 1
	
.loop_animation:
	call set_cursor_position
	call display_progress_bar
	inc dh
	cmp dh, 12
	je fim
	jmp .loop_animation

	;; Rotina para imprimir a barra de progresso do teste
	;; DEPENDÊNCIA: Utilizar set_cursor_position para dizer onde o cursor está
display_progress_bar:

.init:
	push dx
	mov cl, 8
.loop:
	cmp cl, 0
	je .loop_end
	
	mov bx, 4
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
	;; (BX) - Deve conter a quantidade de ticks (18 ticks = 1 segundo)
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
	jmp .testing_aa

.loop:
	cmp si, di
	je .mem_test_end
	inc si
	
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
	
.mem_test_end:
	jmp fim

.mem_error:
	;; implementar o caso de erro de memória

	;; Rotina que realiza o teste de memória nos endereços mais altos (Endereço > 0xFFFF (0x10000)
	;; (SI) - Deve apontar para endereço inicial
	;; (DI) - Deve apontar para endereço final
mem_test_high_addr:	
	jmp .testing_aa

.loop:
	cmp si, di
	je .mem_test_end
	inc si
	
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

.mem_test_end:
	jmp fim

.mem_error:
	
	
	;; Rotina que exibe o layout de memória da máquina
display_mem_layout:	
	mov ch, 4
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

.init:
	mov ch, STR_ADDR_SIZE
	mov si, str_addr1
	mov dl, 8
	
.print:
	cmp dl, 0
	je .mem_layout_end
	
	mov bx, show_status
	call print_string
	
	mov bx, si
	call print_addr

	mov bx, space_between_addr
	call print_string

	add si, 5
	mov bx, si
	call print_addr

	add si, 5
	call print_line_break
	
	dec dl
	jmp .print

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

	;; Rotina para impressão de strings na tela em modo TTY (Teletype)
	;; (BX) - Deve conter o endereço inicial da string
print_string:
	push ax
	push bx
	pushf
	mov ah, 0x0e
.print:
	mov al, [bx]
	cmp al, 0
	je .print_end
	int 0x10
	inc bx
	jmp .print
.print_end:
	popf
	pop bx
	pop ax
	ret

	;; 0xA  4    8    F

	;; 1010 0100 1000 1111

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

	;; Zerar a máscara hex_out (0x0000)
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

	;; Final do Programa
fim:
	jmp fim

	;; Variáveis Globais

	;; Variáveis de exibição
hex_out: 		db "0x0000", 0
show_status:		db "[", 32, 32, 32, 32, 32, 32, 32, 32, "] ", 0
space_between_addr:	db " - ", 0

	;; Endereços mais baixos
addr1:			dw IVT_START
addr2:			dw BDA_START
addr3:			dw LOW_FREE_MEM_START
addr4:			dw PROG_START
addr5:			dw HIGH_FREE_MEM_START

	;; Endereços mais altos
str_addr1:		db "07E00"
str_addr2:		db "1BCFF"
str_addr3:		db "1BD00"
str_addr4:		db "2FBFF"
str_addr5:		db "2FC00"
str_addr6:		db "43AFF"
str_addr7:		db "43B00"
str_addr8:		db "579FF"
str_addr9:		db "57A00"
str_addr10:		db "6B8FF"
str_addr11:		db "6B900"
str_addr12:		db "7F7FF"
str_addr13:		db "7F800"
str_addr14:		db "936FF"
str_addr15:		db "93700"
str_addr16:		db "9FBFF"

	;; Definição que o tamanho do arquivo tenha exatos 512 bytes (tamanho de um setor)
	;; E escrita da assinatura (0xaa55) para que a BIOS reconheça como bootável
	times 510-($-$$) db 0
	dw 0xaa55	
