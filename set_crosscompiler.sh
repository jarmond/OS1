#/bin/sh

CROSSDIR=$HOME/code/os/cross
export CC=$CROSSDIR/bin/i686-elf-gcc
export CPP=$CROSSDIR/bin/i686-elf-cpp
export LD=$CROSSDIR/bin/i686-elf-ld
export OBJDUMP=$CROSSDIR/bin/i686-elf-objdump
export NM=$CROSSDIR/bin/i686-elf-nm

alias gcc=$CC
alias ld=$LD
alias objdump=$OBJDUMP
alias nm=$NM

