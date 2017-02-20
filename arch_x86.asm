;;; Assembly routines for jOS implementation.

global _outb
global _inb
global _bochs_break

section .text
_outb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        mov     al, [ebp+12]    ; byte to send
        out     dx, al          ; send byte
        leave
        ret

_inb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        in      al, dx          ; receive byte
        leave
        ret

_bochs_break:
        xchg    bx, bx
        ret

