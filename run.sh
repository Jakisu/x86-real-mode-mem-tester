#!/bin/bash

# Por padrão é feito execução com o QEMU. Caso queira com o Bochs comente a linha do QEMU e descomente do Bochs.

qemu-system-i386 -drive file=disco_virtual.img,format=raw

# bochs -qf bochsrc.txt
