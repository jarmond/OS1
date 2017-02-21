#ifndef ARCH_X86_H
#define ARCH_X86_H
/* Assembly routines for OS1 */

/* Send byte to address. */
void outb(void* addr, char byte);

/* Read byte from address. */
char inb(void* addr);

#endif
