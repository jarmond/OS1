# Makefile for jOS

CC=/Users/jon/code/os/cross/bin/i686-elf-gcc
LD=/Users/jon/code/os/cross/bin/i686-elf-ld
AS=/usr/local/bin/nasm

CFLAGS=-Wall -Wextra -Werror -m32 -nostdlib -fno-builtin -nostartfiles -nodefaultlibs

# kernel is first to put _start at beginning.
CSRC=kernel_main.c sys.c vga.c bochs.c
COBJ=$(CSRC:.c=.o)
ASRC=arch_x86.asm
AOBJ=$(ASRC:.asm=.o)

all: boot

%.o : %.c
	${CC} -ggdb -Wall -ffreestanding -o $@ -c $<

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
	${AS} -Wall -f elf32 -l $@.lst -o $@.o $<

# Compile kernel and strip header.
kernel: arch_x86 ${COBJ}
	${CC} -T link.ld ${COBJ} ${AOBJ} -ggdb -o $@.bin -nostdlib -ffreestanding -lgcc

clean:
	rm -f bootldr *.lst boot.img *.o *.bin

