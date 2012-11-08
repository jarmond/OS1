;;; Assembly routines for OS implementation.

global _outb
global _inb
global _print_char
        
_outb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        mov     al, [ebp+12]    ; byte to send
        out     dx, al          ; send byte
        pop     ebp
        ret

_inb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        in      al, dx          ; receive byte
        pop     ebp
        ret

_print_char:
        push    ebp
        mov     ebp, esp
        mov     al, [ebp+8]     ; char to print
        mov     ah, 0x0e        ; print char code
        mov     bx, 0x07        ; grey on black, page zero
        int     0x10            ; call BIOS text write
        pop     ebp
        ret
        
        
