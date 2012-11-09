/* Kernel C source. */

#include "arch_x86.h"
#include "sys.h"

void __start()
{
    bochs_break();

    while (1)
        kprint("Hello world\n");
}
