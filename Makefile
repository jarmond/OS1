# Makefile for jOS

CC=gcc-6
LD=ld
AS=/usr/local/bin/nasm

CFLAGS=-Wall -Wextra -Werror -m32 -nostdlib -fno-builtin -nostartfiles -nodefaultlibs

CSRC=sys.c vga.c kernel_main.c
COBJ=$(CSRC:.c=.o)
ASRC=arch_x86.asm
AOBJ=$(ASRC:.asm=.o)

all: boot

%.o : %.c
	${CC} -Wall -m32 -nostdlib -o $@ -c $<

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

# Compile kernel assembly.
arch_x86: ${ASRC}
	${AS} -Wall -f macho32 -l $@.lst -o $@.o $<

# Compile kernel and strip header.
kernel: arch_x86 ${COBJ}
	${LD} arch_x86.o ${COBJ} -o $@.bin -r -U _main -arch i386 -macosx_version_min 10.10 -no_pie -segaddr _text 0x1000

clean:
	rm -f bootldr *.lst boot.img *.o *.bin

