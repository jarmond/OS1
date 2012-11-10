/* Kernel system calls. */

#include "vga.h"


void kprint(const char* s)
{

    while (*s != '\0') {
        if (*s == '\n') {
            // Handle new lines.
            vga_new_line();
        } else {
            vga_print_char(*s);
        }

        ++s;
    }
}
