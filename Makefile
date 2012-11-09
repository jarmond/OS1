# Makefile for OS

CC=/Users/jon/oscross/bin/i586-elf-gcc
LD=/Users/jon/oscross/bin/i586-elf-ld
AS=nasm

CFLAGS=-Wall -m32 -nostdlib


CSRC=sys.c
COBJ=$(CSRC:.c=.o)
ASRC=arch_x86.asm

all: boot

boot: boot.img

boot.img: bootldr kernel
	dd if=/dev/zero bs=1k count=1440 of=$@
# Boot loader to first sector.
	dd if=bootldr bs=512 count=1 of=$@ conv=notrunc
# Kernel to second track onwards.
	dd if=kernel.bin bs=512 seek=36 count=1440 of=$@ conv=notrunc

# Assemble bootloader.
bootldr: bootldr.asm
	${AS} -Wall -f bin -l $@.lst -o $@ bootldr.asm

# Compile kernel main.
#kernel_main: kernel_main.c
#	${CC} -Wall -m32 -nostdlib -o $@.o -c $<


# Compile kernel assembly.
arch_x86: arch_x86.asm
	${AS} -Wall -f elf32 -l $@.lst -o $@.o $<


# Compile kernel and strip header.
kernel: kernel_main.o arch_x86 ${COBJ}
	${LD} kernel_main.o arch_x86.o ${COBJ} -o $@.bin --oformat=binary -Ttext=0xf000 -e 0x0
# Also make an ELF version to aid disassembly.
	${LD} kernel_main.o arch_x86.o ${COBJ} -o $@.elf -Ttext=0xf000 -e 0x0

#	${LD} kernel.o kernel_asm.o $(CSRC:.c=.o) -o $@_1.bin -U start -arch i386 -macosx_version_min 10.5 -segaddr _text 0x1000
#	dd if=$@_1.bin of=$@.bin ibs=3776 skip=1


clean:
	rm -f bootldr *.lst boot.img *.o *.bin

