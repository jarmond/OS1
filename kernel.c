/* Kernel C source. */

#include "asm.h"

void __start()
{
    while (1)
        print_char('c');
}
