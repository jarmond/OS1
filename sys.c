/* Kernel system calls. */

#define VGA_BUFFER 0xb8000
#define VGA_LINES 25
#define VGA_COLUMNS 80
#define VGA_CHARSIZE 2
#define VGA_COLOR 0xa

#include "arch_x86.h"

inline volatile char* vga_ptr_offset(int line, int cursor)
{
    return (volatile char*) (VGA_BUFFER + VGA_CHARSIZE *
                             (line * VGA_COLUMNS + cursor));
}

void kprint(const char* s)
{
    static int vga_cursor = 0;
    static int vga_line = 0;

    while (*s != '\0') {
        if (*s == '\n') {
            // Handle new lines.
            ++vga_line;
            vga_cursor = 0;
        } else {
            // Cursor location.
            volatile char* vga_ptr = vga_ptr_offset(vga_line, vga_cursor);
            *vga_ptr++ = *s;
            *vga_ptr = VGA_COLOR;

            ++vga_cursor;
            // Wrap line.
            if (vga_cursor >= VGA_COLUMNS) {
                ++vga_line;
                vga_cursor = 0;
            }
        }

        ++s;
    }
}
