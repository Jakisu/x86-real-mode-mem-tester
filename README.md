# Testador de Memória para PC IA-32 (x86) Modo Real

## Depêndências

### Para Sistemas GNU/Linux Baseados em Debian:

### - Utilitários Binários Básicos

$ apt install binutils make

### - Montador (Assembler)

Como montador do projeto é utilizado o [NASM](https://www.nasm.us/)

$ apt install nasm

### - Emulador de PC IA-32 (x86)

Para o emulador de PC IA-32 (x86) é possível utilizar duas opções:

#### 1. [QEMU](https://www.qemu.org/)

Para execução convencional padrão o QEMU serve perfeitamente.

$ apt install qemu-system-x86

#### 2. [Bochs](https://bochs.sourceforge.io/)

Como alternativa o Bochs é melhor para depuração e desenvolvimento.

$ apt install bochs

## Build do Programa

$ make -k

## Script Shell de Execução do Programa

### - Adicionar Permissão de Execução

$ chmod +x run.sh

### - Executar Script

$ ./run.sh
