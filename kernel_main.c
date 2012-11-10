/* Kernel C source. */

#include "sys.h"

void __start()
{
    while (1)
        kprint("Hello world\n");
}
