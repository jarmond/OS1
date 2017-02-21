/* Linker script for building kernel */

kernelAddr = 0x1000;
ENTRY(_start)

SECTIONS
{
      . = kernelAddr;

      /* Code */
      .text BLOCK(4K) : ALIGN(4K)
      {
          *(.text)
      }

      /* Read-only data */
      .rodata BLOCK(4K) : ALIGN(4K)
      {
          *(.rodata)
      }

      /* Initialized data */
      .data BLOCK(4K) : ALIGN(4K)
      {
          *(.data)
      }

      /* Uninitialized data and stack */
      .bss BLOCK(4K) : ALIGN(4K)
      {
          *(COMMON)
          *(.bss)
      }
}
