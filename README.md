# jOS - Jon's operating system

This a operating system project for the purposes of the self-learning.

## Usage

Compile bootloader, kernel and libaries using the Makefile. This requires gcc and a recent version of nasm (Homebrew).

```
make
```

Run using the Bochs x86 emulator.

```
bochs -f bochsrc
```

### Architecture

The OS is designed to map onto a (virtual) floppy disk with no filesystem.

Bootloader is in bootldr.asm. It is designed to fit into the first sector of the disk (512 bytes). Space is left on the first track for loading an extended bootloader (not implemented). The kernel is installed on the remaining tracks.

The bootloader sets the video mode and prints some wakeup message. It then loads the kernel track-by-track into memory (see bootldr.asm for memory map).
After loading the kernel, it enters protected mode and jumps to kernel start (0xf000).
