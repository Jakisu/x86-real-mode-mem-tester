# Variáveis de Build
ASM=nasm

.PHONY: all clear

all: disco_virtual.img

# Imagem de um Disco Virtual (Imagem de um Disquete 1.44MB)
disco_virtual.img: mem_tester.bin
	dd if=/dev/zero of=disco_virtual.img bs=512 count=2880
	dd if=mem_tester.bin of=disco_virtual.img conv=notrunc

# Montagem do Programa Testador de Memória
mem_tester.bin: mem_tester.asm
	$(ASM) mem_tester.asm -f bin -o mem_tester.bin

# Limpar o Build
clean:
	rm -f mem_tester.bin disco_virtual_img

