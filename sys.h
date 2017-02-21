#ifndef SYS_H
#define SYS_H
/* OS1 kernel system calls. */

/* Initialize system. */
void kinit();

/* Print string to terminal. */
void kprint(const char* s);

#endif
