/* Kernel C source. */

#include "arch_x86.h"

void __start()
{
    while (1)
        print_char('c');
}
