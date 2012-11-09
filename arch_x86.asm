;;; Assembly routines for jOS implementation.

global outb
global inb
global print_char

        ;; Data
        gdt_limit       dw      39      ; 5 8-byte descriptors (n*8-1)
        gdt_base        dd      0x1000  ; base linear addr of GDT

        
setup_gdt:
        ;; Prepare GDT
        cli
        mov     ax, gdt_base
        mov     ds, ax
        mov     si, 0
        ;; Null descriptor
        mov     [ds:si], dword 0 
        mov     [ds:si+4], dword 0

        ;; Ring 0 Code descriptor
        add     si, 8
        mov     [ds:si], word 0xffff ; segment limit (low 16 bits) = 4GB
        mov     [ds:si+2], word 0    ; base address (low word) = 0
        mov     [ds:si+4], word 0x9800 ; (low) base address (bits 16-23) = 0
                                       ; (hi) execute-only, ring=0
        mov     [ds:si+6], word 0xcf ; segment limit (high 4 bits), 32-bit
                                     ; 4kb granularity
                                     ; base addr (bits 24-31) = 0

        ;; Ring 0 Data descriptor: as above except expand-up, data-segment
        add     si, 8
        mov     [ds:si], word 0xffff
        mov     [ds:si+2], word 0
        mov     [ds:si+4], word 0x9200 ; (hi) expand-up, ring=0, r/w
        mov     [ds:si+6], word 0xcf

        ;; Ring 3 Code descriptor
        add     si, 8
        mov     [ds:si], word 0xffff
        mov     [ds:si+2], word 0
        mov     [ds:si+4], word 0xf800 ; ring=3
        mov     [ds:si+6], word 0xcf

        ;; Ring 3 Data descriptor
        add     si, 8
        mov     [ds:si], word 0xffff
        mov     [ds:si+2], word 0
        mov     [ds:si+4], word 0xf200 ; ring=3
        mov     [ds:si+6], word 0xcf
        
        lgdt    [gdt_limit]
        sti

        
outb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        mov     al, [ebp+12]    ; byte to send
        out     dx, al          ; send byte
        pop     ebp
        ret

inb:
        push    ebp
        mov     ebp, esp
        mov     dx, [ebp+8]     ; address
        in      al, dx          ; receive byte
        pop     ebp
        ret

print_char:
        push    ebp
        mov     ebp, esp
        mov     al, [ebp+8]     ; char to print
        mov     ah, 0x0e        ; print char code
        mov     bx, 0x07        ; grey on black, page zero
        int     0x10            ; call BIOS text write
        pop     ebp
        ret
        
        
