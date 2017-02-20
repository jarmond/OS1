# Makefile for jOS

CC=gcc-6
LD=ld
AS=/usr/local/bin/nasm

CFLAGS=-Wall -Wextra -Werror -m32 -nostdlib -fno-builtin -nostartfiles -nodefaultlibs

CSRC=kernel_main.c sys.c vga.c # kernel is first to put _start at beginning.
COBJ=$(CSRC:.c=.o)
ASRC=arch_x86.asm
AOBJ=$(ASRC:.asm=.o)

all: boot

%.o : %.c
	${CC} -g -Wall -march=i386 -m32 -nostdlib -o $@ -c $<

boot: boot.img

boot.img: bootldr kernel
	dd if=/dev/zero bs=1k count=1440 of=$@
# Boot loader to first sector.
	dd if=bootldr bs=512 count=1 of=$@ conv=notrunc
# Kernel to second track onwards, 2880 sectors - 36.
	dd if=kernel.bin bs=512 seek=36 count=2844 of=$@ conv=notrunc

# Assemble bootloader.
bootldr: bootldr.asm
	${AS} -Wall -f bin -l $@.lst -o $@ bootldr.asm

# Compile kernel assembly.
arch_x86: ${ASRC}
	${AS} -Wall -f macho32 -l $@.lst -o $@.o $<

# Compile kernel and strip header.
kernel: arch_x86 ${COBJ}
	${LD} ${COBJ} arch_x86.o -o $@_1.bin -r -U _main -arch i386 -macosx_version_min 10.10 -no_pie -segaddr _text 0x1000
# Strip header from above so _start function is first byte.
	dd if=$@_1.bin of=$@.bin ibs=496 skip=1

clean:
	rm -f bootldr *.lst boot.img *.o *.bin

