/* VGA driver */

#include "vga.h"

#include "arch_x86.h"

#define VGA_BUFFER 0xb8000
#define VGA_LINES 25
#define VGA_COLUMNS 80
#define VGA_CHARSIZE 2
#define VGA_COLOR 0xa

#define CRTC_ADDRESS_REG  (void*)0x03d4
#define CRTC_ACCESS_REG   (void*)0x03d5
#define CRTC_CURSOR_START    0x0a
#define CRTC_CURSOR_LOC_HIGH 0x0e
#define CRTC_CURSOR_LOC_LOW  0x0f

int vga_column = 0;
int vga_line = 0;


inline static volatile char* vga_ptr_offset(int line, int column)
{
    return (volatile char*) (VGA_BUFFER + VGA_CHARSIZE *
                             (line * VGA_COLUMNS + column));
}

void vga_print_char(char c)
{
    // Update video memory.
    volatile short* vga_ptr = (volatile short*) vga_ptr_offset(vga_line, vga_column);
    short cell = (VGA_COLOR << 8) | c;
    *vga_ptr = cell;

    // Increment cursor.
    ++vga_column;
    // Wrap line.
    if (vga_column >= VGA_COLUMNS) {
        ++vga_line;
        vga_column = 0;
    }

    vga_move_cursor(vga_line, vga_column);
}

void vga_new_line()
{
    ++vga_line;
    vga_column = 0;
}

void vga_enable_cursor()
{
    // Set CRTC address.
    outb(CRTC_ADDRESS_REG, CRTC_CURSOR_START);
    char reg = inb(CRTC_ACCESS_REG);
    // Set bit 5 to 1.
    outb(CRTC_ACCESS_REG, reg | 0x10);
}

void vga_disable_cursor()
{
    // Set CRTC address.
    outb(CRTC_ADDRESS_REG, CRTC_CURSOR_START);
    char reg = inb(CRTC_ACCESS_REG);
    // Set bit 5 to 0.
    outb(CRTC_ACCESS_REG, reg & ~0x10);
}

void vga_move_cursor(int line, int column)
{
    vga_line = line;
    vga_column = column;
    short cursor = line * VGA_LINES + column;
    // Set cursor loc low bits.
    outb(CRTC_ADDRESS_REG, CRTC_CURSOR_LOC_LOW);
    outb(CRTC_ACCESS_REG, cursor);
    // Set cursor loc high bits.
    outb(CRTC_ADDRESS_REG, CRTC_CURSOR_LOC_LOW);
    outb(CRTC_ACCESS_REG, cursor >> 8);
}
