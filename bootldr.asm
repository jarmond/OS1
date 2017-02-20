;;; Simple bootloader for jOS
;;; (c)2012 J. W. Armond
;;; Written for NASM

;;; Memory map
;;; 100000 Top of low memory
;;; 0a0000-0fffff Video memory
;;; 09fc00-09ffff Extended BIOS data area
;;; 00f000-09fc00 Kernel preload (576 kb)
;;; 00d000-00efff Extended bootloader (8 kb)
;;; 008000-00c800 Disk buffer (18432 bytes = 36 sectors == 1 track)
;;; 007c00-007dff Bootloader (512 bytes)
;;; 006000-007000 Real-mode stack
;;; 002000-003000 Memory map
;;; 001000-001020 GDT 8-byte aligned
;;; 000400-0004ff BIOS data area
;;; 000000-0003ff Real mode IVT

;;; Disk map
;;; t0 h0 s1             bootloader
;;; t0 h0 s2..18         extended bootloader if needed
;;; t1..32 h0..1 s1..18  kernel

        [bits 16]               ; 16-bit mode
        org     0
        jmp     start
        nop

        ;; Data
        version         db      'jOS',0
        kernel_loaded   db      'kernel loaded!',0
        a20_error       db      'A20 err',0
        disk_error      db      'Disk err ',0
        drive_num       db      0
        gdt_limit       dw      39      ; 5 8-byte descriptors (n*8-1)
        gdt_base        dd      0x1000  ; base linear addr of GDT

        kernel_tracks   equ     31
        kernel_seg      equ     0xf00
        kernel_off      equ     0x0
        kernel_start    equ     0xf000
        disk_buf        equ     0x800
        disk_buf_size   equ     0x4800
        mmap_start      equ     0x200
        mmap_entry_size equ     24
        mmap_magic      equ     0x534d4150

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

        ;; Set video mode to 3
        mov     ax, 3
        int     0x10

        ;; Clear screen
        call    clear_screen

        ;; Set cursor to top left
        mov     ah, 0x02
        mov     bh, 0
        xor     dx, dx
        int     0x10

        ;; Print greeting
        mov     si, version
        call    print_message

        ;; A20 gate enable
        mov     ax, 0x2401
        int     0x15
        cmp     ah, 0x86
        jz      a20_fail

        ;; Load kernel into memory
        mov     ah, 0           ; floppy controller reset
        mov     dl, [drive_num] ; drive number
        int     0x13
        jc      disk_fail

        push    ds
        mov     cx, 1           ; track counter
        mov     dh, 0           ; start with head 0
        mov     bx, kernel_seg  ; kernel preload segment
        mov     ds, bx
        mov     bx, disk_buf    ; disk buffer segment
        mov     es, bx

read_track:
        shl     cx, 8           ; track to read to ch
        mov     cl, 1           ; sector to start
        xor     bx, bx          ; segment offset
read_head:
        mov     ax, 0x0212      ; ah=0x02 (read sectors), al=18 sectors
        int     0x13
        jc      disk_fail

        cmp     dh, 0           ; if head 0, do head 1
        jnz     goto_next_track
        inc     dh              ; set head 1
        add     bx, disk_buf_size/2   ; increment buffer offset
        jmp     read_head

goto_next_track:
        ;; Print track dot
        mov     ax, 0x0e2e      ; ah=0x0e, al='.'
        mov     bx, 0x07
        int     0x10

        ;; Copy track from disk buffer to kernel
        push    es              ; disk buffer
        push    ds              ; kernel
        push    word disk_buf_size   ; number of bytes to copy
        call    copy_buffer

        ;; Increment kernel segment
        mov     ax, ds
        add     ax, 0x480       ; increment buffer addr by 0x4800 bytes
                                ; = 1 track, 1 heads, 18 sectors
        mov     ds, ax

        mov     dh, 0           ; return to head 0
        shr     cx, 8           ; restore track counter
        inc     cx              ; move to next track
        cmp     cx, kernel_tracks
        jnz     read_track

        ;; Kernel loaded
        pop     ds

        mov     si, kernel_loaded
        call    print_message

        ;; Read memory map
        push    es
        mov     ax, mmap_start
        mov     es, ax
        xor     di, di
        xor     ebx, ebx
        mov     edx, mmap_magic

read_mmap_entry:
        mov     eax, 0xe820     ; memory detect function
        mov     ecx, mmap_entry_size
        int     0x15

        xchg    bx,bx
        jcxz    read_mmap_entry ; skip zero length entries
        jc      read_mmap_end   ; if CF set, list end
        cmp     eax, mmap_magic
        jnz     read_mmap_end   ; if eax != mmap_magic, list end
        cmp     ebx, 0          ; if ebx == 0, list end
        jz      read_mmap_end
        add     di, mmap_entry_size
        jmp     read_mmap_entry

read_mmap_end:
        pop     es

        ;; Prepare GDT
        cli
        mov     ax, [gdt_base]
        shr     ax, 4
        push    ds
        mov     ds, ax
        xor     si, si
        ;; Null descriptor
        mov     [ds:si], dword 0
        mov     [ds:si+4], dword 0

        ;; Ring 0 Code descriptor
        add     si, 8
        mov     eax, 0xffff
        mov     [ds:si], dword 0xffff ; segment limit (low 16 bits) = 4GB
                                      ; base address (low word) = 0
        mov     [ds:si+4], dword 0xcf9a00 ; (low) base address (bits 16-23) = 0
                                          ; (hi) execute/read, ring=0
                                          ; segment limit (high 4 bits), 32-bit
                                          ; 4kb granularity
                                          ; base addr (bits 24-31) = 0

        ;; Ring 0 Data descriptor: as above except expand-up, data-segment
        add     si, 8
        mov     [ds:si], dword 0xffff
        mov     [ds:si+4], dword 0xcf9200 ; (hi) expand-up, ring=0, r/w

        ;; Ring 3 Code descriptor
        add     si, 8
        mov     [ds:si], dword 0xffff
        mov     [ds:si+4], dword 0xcffa00 ; ring=3

        ;; Ring 3 Data descriptor
        add     si, 8
        mov     [ds:si], dword 0xffff
        mov     [ds:si+4], dword 0xcff200 ; ring=3

        pop     ds
        lgdt    [gdt_limit]

        ;; Set protected mode
        mov     eax, cr0
        or      eax, 1
        mov     cr0, eax

        ;; Reload segment registers
        mov     ax, 0x10        ; Ring0 data descriptor
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax


        xchg    bx,bx
        ;; Load kernel
        jmp     0x08:kernel_start        ; Ring0 code descriptor


disk_fail:
        mov     bh, ah          ; save error code
        mov     si, disk_error
        call    print_message
        jmp     idle

a20_fail:
        mov     si, a20_error
        call    print_message

idle:
        hlt
        jmp     idle


;;; SUBROUTINES

;;; Copy data from buffer to buffer.
;;; Takes on stack: src segment, dst segment, number of bytes
;;; Uses zero offset. Clobbers si, di, bp.
copy_buffer:
        mov     bp, sp
        push    ds
        push    es
        push    cx

        mov     ds, [bp+6]      ; src
        mov     es, [bp+4]      ; dst
        xor     ecx, ecx
        mov     cx, [bp+2]      ; number of bytes
        xor     si, si
        xor     di, di
        rep movsd               ; copy

        pop     cx
        pop     es
        pop     ds
        ret     6


;;; Clear screen
clear_screen:
        mov     ax, 0x0700
        mov     bh, 0x07
        xor     cx, cx
        mov     dh, 24          ; 25 rows
        mov     dl, 79          ; 80 cols
        int     0x10
        ret

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



        ;; Pad to 512 bytes
        times   510-($-$$) db 0 ; pad with zeros
        dw      0xaa55          ; boot signature
