/* Kernel system calls. */

#include "vga.h"
#include "arch_x86.h"

void kinit()
{
    vga_initialize(); 
}

void kprint(const char* s)
{
    while (*s != '\0') {
        if (*s == '\n') {
            vga_new_line();
        } else {
            vga_print_char(*s);
        }

        ++s;
    }
}
