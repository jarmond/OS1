;;; Simple bootloader for jOS
;;; (c)2012 J. W. Armond
;;; Written for NASM

;;; Memory map
;;; 100000 Top of low memory
;;; 00f000-09f000 Kernel preload (576 kb)
;;; 008000-00c7ff Disk buffer (18432 bytes)
;;; 007c00-007dff Bootloader (512 bytes)
;;; 006000-007000 Real-mode stack
;;; 001000 GDT 8-byte aligned
;;; 000000 Reserved

;;; Disk map
;;; t0 h0 s1             bootloader
;;; t0 h0 s2..18         extended bootloader if needed
;;; t1..32 h0..1 s1..18  kernel
        
        [bits 16]               ; 16-bit mode
        org     0
        jmp     start
        nop
        
        ;; Data
        version         db      'JWA OS',13,10,0
        loading         db      'Loading...',13,10,0
        kilobyte        db      'kb',0
        low_mem         db      ' low mem',13,10,0
        ext_mem         db      ' ext mem',13,10,0
        a20_error       db      'A20 gate fail',13,10,0
        disk_error      db      'Disk err ',0
        newline         db      13,10,0
        drive_num       db      0

        gdt_limit       dw      24 ; 3 8-byte descriptor
        gdt_base        dd      0x1000

        kernel_tracks   equ     31
        kernel_seg      equ     0xf00
        disk_buf        equ     0x800

start:  
        mov     ax, 0x7c0       ; bootloaders loaded from 0x7c00
        mov     ds, ax          ; setup data segment

        ;; Set up stack
        cli
        mov     ax, 0x600      ; put stack top at linear 0x07000
        mov     ss, ax
        mov     sp, 0x1000     ; stack grows down
        sti

        mov     [drive_num], dl   ; record drive number
        
        ;; Clear screen
        call    clear_screen

        ;; Set cursor to top left
        mov     ah, 0x02
        mov     bh, 0
        mov     dx, 0
        int     0x10
        
        ;; Print some infomation
        mov     si, version
        call    print_message

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

        ;; A20 gate enable
        mov     ax, 0x2401
        int     0x15
        cmp     ah, 0x86
        jz      a20_fail

        ;; Load kernel into memory
        xchg    bx, bx
        mov     si, loading
        call    print_message
        mov     ah, 0           ; floppy controller reset
        int     0x13
        mov     cx, 1           ; track counter
        mov     dh, 0           ; start with head 0
        mov     dl, [drive_num] ; drive number
        mov     bx, kernel_seg  ; kernel preload segment
        mov     es, bx
        mov     bx, 0           ; segment offset

read_track:     
        mov     ah, 0x02        ; read sectors
        mov     al, 18          ; # sectors to read
        shl     cx, 8           ; track to read to ch
        mov     cl, 1           ; sector to start
        int     0x13

        
        cmp     dh, 0           ; if head 0, do head 1
        jnz     goto_next_track
        inc     dh              ; set head 1
        add     bx, 0x240       ; set disk buffer offset for next head
        jmp     read_track

        ;; Print track dot
        mov     ax, 0x0e2e
        mov     bx, 0x07
        int     0x10

goto_next_track:
        mov     bx, es
        add     bx, 0x480       ; increment segment selector by 0x4800 bytes
                                ; = 1 track, 2 heads, 18 sectors
        mov     es, bx
        mov     dh, 0           ; return to head 0
        shr     cx, 8           ; restore track counter
        inc     cx              ; move to next track
        cmp     cx, kernel_tracks
        jnz     read_track      
        

        ;; Prepare GDT
        mov     si, 0
        ;; Null descriptor
        mov     [ds:si], dword 0 
        mov     [ds:si+4], dword 0

        ;; Code descriptor
        add     si, 8
        mov     [ds:si], word 0xffff ; segment limit (low 16 bits) = 4GB
        mov     [ds:si+2], word 0    ; base address (low word) = 0
                             ; al: base address (high word-low byte) = 0
        mov     ax, 0x9800   ; ah: DPL 0, execute-only, present, code segment
        mov     [ds:si+4], ax
        mov     ax, 0xcf     ; segment limit (high 4 bits), 32-bit
                             ; 4kb granularity
        mov     [ds:si+6], ax

        ;; Data descriptor: as above except expand-up, data-segment
        add     si, 8
        mov     [ds:si], word 0xffff
        mov     [ds:si+2], word 0
        mov     ax, 0x9200
        mov     [ds:si+4], ax
        mov     ax, 0xcf
        mov     [ds:si+6], ax

        cli
        lgdt    [gdt_limit]

        ;; Set protected mode
        mov     eax, cr0
        or      eax, 1
        mov     cr0, eax

        ;; Load kernel
        jmp dword kernel_seg:0
        
disk_fail:
        mov     si, disk_error
        call    print_message
        shr     ax, 8           ; ah has error, put ah in al
        xor     ah, ah
        call    print_integer
        mov     si, newline
        call    print_message
        jmp     idle
        
a20_fail:
        mov     si, a20_error
        call    print_message
        
idle:
        hlt
        jmp     idle


;;; SUBROUTINES
        
;;; Clear screen
clear_screen:   
        mov     ax, 0x0700
        mov     bh, 0x07
        xor     cx, cx
        mov     dh, 24          ; 25 rows
        mov     dl, 79          ; 80 cols
        int     0x10

;;; Print message at ds:si
print_message:
        lodsb                   ; load a byte into al
        or      al, al
        jz      print_message_end ; if null, finished
        mov     ah, 0x0e        ; print char
        mov     bx, 0x07        ; grey on black, page zero
        int     0x10
        jmp     print_message
print_message_end:      
        ret

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
        
        ;; Pad to 512 bytes
        times   510-($-$$) db 0 ; pad with zeros
        dw      0xaa55          ; boot signature
        
