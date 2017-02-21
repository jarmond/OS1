#ifndef BOCHS_H
#define BOCHS_H

/* OS1 Bochs debugging routines. */

/* Print single character to Bochs debug console. */
void bochs_putc(char c);

/* Print null-terminated string to Bochs debug console. */
void bochs_print(const char* c);

/* Trigger Bochs breakpoint. */
void bochs_break();


#endif
