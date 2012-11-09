;;; old stuff removed from bootldr.asm to save space.
        
        loading         db      'Loading...',13,10,0
        kilobyte        db      'kb',0
        low_mem         db      ' low mem',13,10,0
        ext_mem         db      ' ext mem',13,10,0

        
        ;; Query low memory size
        int     0x12            ; kb in ax
        call    print_integer
        mov     si, kilobyte
        call    print_message
        mov     si, low_mem
        call    print_message

        ;; Query extended memory size
        mov     ah, 0x88
        int     0x15            ; if success, kb in ax
        call    print_integer
        mov     si, kilobyte
        call    print_message
        mov     si, ext_mem
        call    print_message

        ;; Load kernel into memory
        mov     si, loading
        call    print_message


disk_fail:
        mov     si, disk_error
        call    print_message
        shr     ax, 8           ; ah has error, put ah in al
        xor     ah, ah
        call    print_integer
        mov     si, newline
        call    print_message
        jmp     idle



;;; Print unsigned 16-bit integer in ax
;;; void print_int(int n)
;;; In: n (eax)
print_integer:
        push    ds
        sub     sp, 6           ; allocate 6-byte buffer on stack
        call    write_integer_u16
        mov     ax, ss          ; make buffer available to print_message
        mov     ds, ax
        mov     si, sp
        call    print_message
        add     sp, 6           ; release buffer
        pop     ds
        ret
        
print_integer_end:      
        
;;; Write unsigned 16-bit integer in ax as decimal nul-term string into
;;; 6-byte buffer on stack
write_integer_u16:
        mov     bp, sp
        mov     di, 7           ; 6-byte buffer + ret addr
        mov     [bp+di], byte 0 ; write nul-terminator
        mov     cx, 5           ; 5 decimal digits to write

write_integer_u16_divide:
        xor     dx, dx
        mov     bx, 10          ; divisor
        div     bx              ; remainder in dx
        dec     di              ; move cursor
        xchg    ax, dx          ; quotient in dx, remainder in ax
        cmp     dx, 0           ; if quotient zero, check remainder
        jz      write_integer_u16_blank
write_integer_u16_digit:        
        add     al, 0x30        ; convert remainder to ASCII
        jmp     write_integer_u16_copychar
write_integer_u16_blank:
        cmp     ax, 0           ; if remainder also zero, print blank
        jnz     write_integer_u16_digit
        mov     al, 0x20        ; blank
write_integer_u16_copychar:
        mov     [bp+di], al

        mov     ax, dx
        loop    write_integer_u16_divide
        
write_integer_u16_end:
        ret
        
