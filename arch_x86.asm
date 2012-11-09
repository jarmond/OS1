;;; Assembly routines for jOS implementation.

global outb
global inb
global print_char
global bochs_break

        
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

print_char:
        push    ebp
        mov     ebp, esp
        mov     al, [ebp+8]     ; char to print
        mov     ah, 0x0e        ; print char code
        mov     bx, 0x07        ; grey on black, page zero
        int     0x10            ; call BIOS text write
        leave
        ret
        
bochs_break:
        xchg    bx, bx
        ret
