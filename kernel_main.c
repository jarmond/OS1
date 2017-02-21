/* Kernel C source. */

#include "sys.h"
#include "arch_x86.h"

void _start()
{
  char c='.';
  while (1) {
    outb((void*) 0xe9, c);
    kprint("Hello world\n");
  }
}
