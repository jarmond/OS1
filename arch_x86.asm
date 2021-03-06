;;; Assembly routines for OS1 implementation.

global outb
global inb
global bochs_break

section .text
outb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        mov     al, [ebp+12]    ; byte to send
        out     dx, al          ; send byte
        leave
        ret

inb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        in      al, dx          ; receive byte
        leave
        ret

