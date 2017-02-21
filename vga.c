/* VGA driver */

#include "vga.h"

#include "arch_x86.h"

#include <stddef.h>
#include <stdint.h>

enum vga_colour_t {
    VGA_COLOUR_BLACK = 0,
    VGA_COLOUR_BLUE = 1,
    VGA_COLOUR_GREEN = 2,
    VGA_COLOUR_CYAN = 3,
    VGA_COLOUR_RED = 4,
    VGA_COLOUR_MAGENTA = 5,
    VGA_COLOUR_BROWN = 6,
    VGA_COLOUR_LIGHT_GREY = 7,
    VGA_COLOUR_DARK_GREY = 8,
    VGA_COLOUR_LIGHT_BLUE = 9,
    VGA_COLOUR_LIGHT_GREEN = 10,
    VGA_COLOUR_LIGHT_CYAN = 11,
    VGA_COLOUR_LIGHT_RED = 12,
    VGA_COLOUR_LIGHT_MAGENTA = 13,
    VGA_COLOUR_LIGHT_BROWN = 14,
    VGA_COLOUR_WHITE = 15,
};

#define VGA_BUFFER_ADDR 0xb8000
#define VGA_ROWS 25
#define VGA_COLUMNS 80
#define VGA_FG_COLOUR VGA_COLOUR_WHITE
#define VGA_BG_COLOUR VGA_COLOUR_BLACK

#define CRTC_ADDRESS_REG  (void*)0x03d4
#define CRTC_ACCESS_REG   (void*)0x03d5
#define CRTC_CURSOR_START    0x0a
#define CRTC_CURSOR_LOC_HIGH 0x0e
#define CRTC_CURSOR_LOC_LOW  0x0f

size_t vga_column;
size_t vga_row;
uint8_t vga_colour;
uint16_t* vga_buffer; 


uint8_t vga_colour_combine(enum vga_colour_t fg, enum vga_colour_t bg)
{
    return fg | bg << 4;
}

uint16_t vga_char(char c, uint8_t colour)
{
    // Combine character and colour.
    return (uint16_t) c | ((uint16_t) colour << 8);
}

void vga_put(char c, uint8_t colour, size_t column, size_t row)
{
    uint16_t vc = vga_char(c, colour);
    vga_buffer[column + row * VGA_COLUMNS] = vc;
}

void vga_initialize()
{
    vga_column = 0;
    vga_row = 0;
    vga_colour = vga_colour_combine(VGA_FG_COLOUR, VGA_BG_COLOUR);
    vga_buffer = (uint16_t*) VGA_BUFFER_ADDR;
    vga_clear_screen();
}

void vga_print_char(char c)
{
    // Update video buffer.
    vga_put(c, vga_colour, vga_column, vga_row);

    // Increment cursor and wrap line.
    if (++vga_column >= VGA_COLUMNS) {
        vga_new_line();
    }

    //vga_move_cursor(vga_line, vga_column);
}

void vga_new_line()
{
    vga_column = 0;
    if (++vga_row >= VGA_ROWS)
        vga_row = 0;
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

void vga_move_cursor(int row, int column)
{
    vga_row = row;
    vga_column = column;
    short cursor = row * VGA_ROWS + column;
    // Set cursor loc low bits.
    outb(CRTC_ADDRESS_REG, CRTC_CURSOR_LOC_LOW);
    outb(CRTC_ACCESS_REG, cursor);
    // Set cursor loc high bits.
    outb(CRTC_ADDRESS_REG, CRTC_CURSOR_LOC_LOW);
    outb(CRTC_ACCESS_REG, cursor >> 8);
}

void vga_clear_screen()
{
    for (size_t x=0; x<VGA_COLUMNS; x++)
        for (size_t y=0; y<VGA_ROWS; y++)
            vga_put(' ', vga_colour, x, y);
}
