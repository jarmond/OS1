#!/bin/bash

SRC=$HOME/src
export PREFIX=$HOME/code/os/cross
export TARGET=i686-elf
export PATH=$PREFIX/bin:$PATH

cd $SRC
mkdir build-binutils
cd build-binutils
../binutils-2.27/configure --prefix=$PREFIX \
                           --target=$TARGET \
                           --with-sysroot \
                           --enable-interwork --enable-multilib \
                           --disable-nls --disable-werror
make
make install

cd $SRC
mkdir build-gcc
cd build-gcc
../gcc-6.3.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c --enable-interwork --enable-multilib --without-headers
make all-gcc
make all-target-libgcc
make install-gcc
make install-target-libgcc
