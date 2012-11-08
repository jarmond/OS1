# Makefile for OS

CC=gcc
AS=nasm

CSRC=kernel.c
ASRC=asm.asm

all: boot

boot: boot.img

boot.img: bootldr kernel
	dd bs=512 count=2880 if=kernel.bin of=$@
	dd bs=512 count=1 conv=notrunc if=bootldr of=$@

# Assemble bootloader.
bootldr: bootldr.asm
	nasm -f bin -l $@.lst -o $@ bootldr.asm

# Compile kernel C source.
kernel_c: ${CSRC}
	gcc -m32 -nostdlib -c $<

# Compile kernel assembly.
kernel_asm: ${ASRC}
	nasm -f macho -l $@.lst -o $@.o $<


# Compile kernel.
kernel: kernel_c kernel_asm
#	ld $(CSRC:.c=.o) -o $@.bin --oformat=binary -Ttext=0x100000
	ld kernel_asm.o $(CSRC:.c=.o) -o $@.bin -U start -arch i386 -macosx_version_min 10.5


clean:
	rm -f bootldr *.lst boot.img *.o

