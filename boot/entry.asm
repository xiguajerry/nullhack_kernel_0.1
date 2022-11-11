;
;             Copyright   (C) 2022 SagiriXiguajerry
;
; this file will be loaded at the physical memory address 0x7c00
; by Basic Input/Output System (BIOS) after 
; Power On Self Test (POST) and other startup routine. Then it
; will move itself out of the way to address 0x90000, and jump
; there.
;
; It then loads "setup" directly after it self (0x90200) and the
; system at 0x10000 via BIOS interrupts.
;
; NOTE: currently, the system is at most 65536*8 bytes long, which
; would be no problem for such a tiny os, even in the future
; development. PLEASE KEEP IT SIMPLE. Therefore, 512 kB for the
; kernel would be enough, especially as this doesn't contain the
; buffer cache as in minix.
;
; The bootloader is made as simple as possible, and continuos read
; errors will result in an unbreakable loop. It loads PRETTY FAST
; by getting whole sectors at a time whenever possible.
;
; PS: Reboot by hand.

;|---------------------Memory Layout in the Real Mode-----------------------|
;| START |  END  |   SIZE   |               DESCRIPTION                     |
;|-------|-------|----------------------------------------------------------|
;| FFFF0 | FFFFF |   16B    |     Entry of BIOS (insn. jmp f000:e05b)       |
;| F0000 | FFFEF | 64kB-16B |       BIOS code segment (F0000-FFFFF)         |
;| C8000 | EFFFF |  160kB   |  Hardware adapter ROM (or Mapping memory I/O) |
;| C0000 | C7FFF |   32kB   |            Video Adapter BIOS                 |
;| B8000 | BFFFF |      ~   |         Video Adapter (Text Mode)             |
;| B0000 | B7FFF |      ~   |        Video Adapter (black-white)            |
;| A0000 | AFFFF |   64kB   |         Video Adapter (colorful)              |
;| 9FC00 | 9FFFF |    1kB   |       EBDA (Extended BIOS Data Area)          |
;| 07E00 | 9FBFF |  622080B |         Usable area (about 608kB)             |
;| 07C00 | 07DFF |   512B   |                   MBR                         |
;| 00500 | 07BFF |  30464B  |         Usable area (about 30kb)              |
;| 00400 | 004FF |   256B   |              BIOS Data Area                   |
;| 00000 | 003FF |    1kB   |          Interrupt Vector Table               |
;|--------------------------------------------------------------------------|

%define ENTRY_ADDR 0x7c00
%define TEXT_MODE_VIDEO_BUFFER 0xb800

%define BOOT_DRIVE 0x8008

%define LOADER_BASE_ADDR 0x800
%define LOADER_START_SECTOR 2

org 0x7c00

__root_start:
jmp 0x07c0:(_entry_32-0x7c00)

_entry_32:
; store the disk where we boot from
    mov [BOOT_DRIVE], dl

; reset segment registers
    mov ax, cs
    mov dx, ax
    mov es, ax
    ; mov ss, ax
    mov sp, 0x7c00
; We can read memory via the segment register DS, but we can also
; use ES. DS will be used in another way, so here we use ES to point
; out the segment where contains VRAM (Video RAM).
;
; Here, DS stands for Data Segment, while ES stands for Extend
; Segment.
;
; NOTE: Intel doesn't allows us to assign a segment register 
; directly. Therefore, we must assign another 16-bit register first,
; then assign the segment register via the assigned 16-bit register.
    mov ax, TEXT_MODE_VIDEO_BUFFER
    mov es, ax
; Now ES contains the pointer to Video Buffer (Text Mode)

_clear_screen:
; In fact, it scrolls up the window.
; AH=0x06, AL=Up_Lines (0 for all)
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0       ; Left Up (0,0)
    mov dx, 0x184f  ; Right Down (79,24)
                    ; In VGA Text Mode, a row contains 80 chars, 25 rows in total.
    int 0x10

_reset_pointer:
    mov ax, 0x02
    mov dx, 0
    mov bh, 0
    mov dh, 0x0
    mov dl, 0x0
    int 0x10

_display_msg1:
    mov byte [es: 0x00], 'R'
    mov byte [es: 0x01],  0xEE
    
    mov byte [es: 0x02], 'e'
    mov byte [es: 0x03], 0xEE
    
    mov byte [es: 0x04], 'a'
    mov byte [es: 0x05], 0xEE
    
    mov byte [es: 0x06], 'd'
    mov byte [es: 0x07], 0xEE
    
    mov byte [es: 0x08], ' '
    mov byte [es: 0x09], 0xEE
    
    mov byte [es: 0x0A], 'D'
    mov byte [es: 0x0B], 0xEE
    
    mov byte [es: 0x0C], 'i'
    mov byte [es: 0x0D], 0xEE
    
    mov byte [es: 0x0E], 's'
    mov byte [es: 0x0F], 0xEE
    
    mov byte [es: 0x10], 'k'
    mov byte [es: 0x11], 0xEE

    push es
    
    mov ax, 0
    mov es, ax

    mov ah, 0x02
    mov ch, 0
    mov cl, 2
    mov dl, [BOOT_DRIVE]
    mov al, 2
    mov dh, 0
    mov bx, LOADER_BASE_ADDR
    int 0x13

    pop es

    mov byte [es: 0x00], 'F'
    mov byte [es: 0x01],  0xEE
    
    mov byte [es: 0x02], 'i'
    mov byte [es: 0x03], 0xEE
    
    mov byte [es: 0x04], 'n'
    mov byte [es: 0x05], 0xEE
    
    mov byte [es: 0x06], 'i'
    mov byte [es: 0x07], 0xEE
    
    mov byte [es: 0x08], 's'
    mov byte [es: 0x09], 0xEE
    
    mov byte [es: 0x0A], 'h'
    mov byte [es: 0x0B], 0xEE
    
    mov byte [es: 0x0C], 'e'
    mov byte [es: 0x0D], 0xEE
    
    mov byte [es: 0x0E], 'd'
    mov byte [es: 0x0F], 0xEE
    
    mov byte [es: 0x10], '!'
    mov byte [es: 0x11], 0xEE

    mov ax, 0
    mov es, ax

    jmp 0:0x800            ; jump to setup

;-------------------------------------------------------
; ebx=logical sector number.
; cx=sectors to read
; di=dest memory
_read_disk_lba:
    mov al, cl
    mov dx, 0x1f2
    out dx, al

    ; low 8bit
    mov al, bl
    mov dx, 0x1f3
    out dx, al

    ; middle 8bit
    shr ebx, 8
    mov al, bl
    mov dx, 0x1f4
    out dx, al

    ; high 8bit
    shr ebx, 8
    mov al, bl
    mov dx, 0x1f5
    out dx, al

    ; high 4bit & device
    shr ebx, 8
    and bl, 0x0f
    or bl, 0xe0
    mov al, bl
    mov dx, 0x1f6
    out dx, al

    ; command
    mov al, 0x20
    mov dx, 0x1f7
    out dx, al

    .check_status:
        nop
        in al, dx
        and al, 0x88
        cmp al, 0x08
        jnz .check_status

    mov ax, cx
    mov dx, 256
    mul dx
    mov cx, ax
    mov bx, di
    mov dx, 0x1f0

    .read_data:
        in ax, dx
        mov [bx], ax
        add bx, 2
        loop .read_data

    ret

; bx=dest memory
; al=sectors to read
; ch=cylinder
; cl=sector
; dh=head (0 or 1)
; dl=disk number
; cx=retries
_read_disk_chs:
    push es
    mov ah, 0x02

._read:
    mov ax, 0
    mov es, ax

    int 0x13

    cmp ah, 0
    je ._ret

    cmp cx, 0
    je ._ret
    dec cx
    jmp ._read

._ret:
    pop es

    ret

;------------------------------------------------------
_placeholder:
times 510-($-$$)    db 0
_magic_number:
                    db 0x55, 0xaa