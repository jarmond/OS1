/* Assembly routines for OS */

/* Send byte to address. */
void outb(void* addr, char byte);

/* Read byte from address. */
char inb(void* addr);

/* Print char vis BIOS. */
void print_char(char c);

