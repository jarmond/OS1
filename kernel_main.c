/* OS1 kernel main loop. */

#include "sys.h"
#include "bochs.h"

void _start()
{
  bochs_print("Starting...");
  kinit();

  while (1) {
    kprint("Hello world\n");
  }
}

