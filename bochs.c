#include "bochs.h"

/* OS1 Bochs debugging routines */

#include "arch_x86.h"

#define BOCHS_PORT (void*)0xe9

void bochs_putc(char c)
{
    outb(BOCHS_PORT, c);
}

void bochs_print(const char* c)
{
    while (*c != '\0') {
        bochs_putc(*c++);
    }
}

void bochs_break()
{
    asm("xchg %%bx,%%bx"
        :
        :
        : "bx");
}
