# Testador de Memória para PC IA-32 (x86)

## Depêndências

### Para Sistemas GNU/Linux Baseados em Debian

### Utilitários Binários Básicos

$ apt install binutils

### Montador (Assembler)

Como montador do projeto é utilizado o [NASM](https://www.nasm.us/)

$ apt install nasm

### Emulador de PC IA-32 (x86)

Para o emulador de PC IA-32 (x86) é possível utilizar duas opções:

#### 1. [QEMU](https://www.qemu.org/)

Para execução convencional padrão o QEMU serve perfeitamente.

$ apt install qemu-system-x86

#### 2. [Bochs](https://bochs.sourceforge.io/)

Como alternativa o Bochs é melhor para depuração e desenvolvimento.

$ apt install bochs

## Script Shell de Execução do Programa

### Adicionar Permissão de Execução:

$ chmod +x run.sh

### Executar Script

$ ./run.sh
