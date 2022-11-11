;
;             Copyright   (C) 2022 SagiriXiguajerry
;
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
;
; TODO: Modify the GDT dynamically accroding to the real memory size
; After enable the Protect Mode, the low 1mB memory should be protected. (DPL 0)
; Then, 0x00010000 to 0x7FFFFFFF is User Space, (DPL 3)
; 0x80000000 to 0xFFFFFFFF is Kernel Space. (DPL 0)

%define ENTRY_ADDR 0x7c00
%define TEXT_MODE_VIDEO_BUFFER 0xb800

%define LOADER_BASE_ADDR 0x800
%define LOADER_START_SECTOR 0x2

%define KERNEL_START_SECTOR 0x4
%define KERNEL_SECTOR_SIZE 0 ; change by hand!!!!
%define KERNEL_BASE_ADDR 0x10000

; -------------------Information Tables fetched from BIOS-------------------
%define INFO_DATA_AREA_HEAD 0x8000

%define MEMORY_TABLE_HEAD INFO_DATA_AREA_HEAD
%define MEMORY_TABLE_LOW_MEM MEMORY_TABLE_HEAD
%define MEMORY_TABLE_HIGH_MEM MEMORY_TABLE_LOW_MEM+2
%define MEMORY_TABLE_CALCED_SIZE MEMORY_TABLE_HIGH_MEM+2
%define MEMORY_TABLE_END MEMORY_TABLE_CALCED_SIZE+4

%define BOOT_DRIVE_HEAD MEMORY_TABLE_END
%define BOOT_DRIVE BOOT_DRIVE_HEAD
%define BOOT_DRIVE_END BOOT_DRIVE+2

%define BOOT_DRIVE_INFO_HEAD BOOT_DRIVE_END+6
%define BOOT_DRIVE_INFO_TYPE BOOT_DRIVE_INFO_HEAD
%define BOOT_DRIVE_INFO_MAX_CYLINDERS BOOT_DRIVE_INFO_TYPE+1
%define BOOT_DRIVE_INFO_MAX_SECTORS BOOT_DRIVE_INFO_MAX_CYLINDERS+2
%define BOOT_DRIVE_INFO_MAX_HEADS BOOT_DRIVE_INFO_MAX_SECTORS+1
%define BOOT_DRIVE_INFO_RESERVED BOOT_DRIVE_INFO_MAX_HEADS+1
%define BOOT_DRIVE_INFO_END BOOT_DRIVE_INFO_MAX_HEADS+1

%define KEYBOARD_LEDS_INFO_HEAD BOOT_DRIVE_INFO_END
%define KEYBOARD_LEDS_INFO KEYBOARD_LEDS_INFO_HEAD
%define KEYBOARD_LEDS_INFO_RESERVED KEYBOARD_LEDS_INFO+1
%define KEYBOARD_LEDS_INFO_END KEYBOARD_LEDS_INFO_RESERVED+1
; --------------------------------------------------------------------------

%define SELECTOR_CODE_REAL      0000000000001_0_00b ; index * 8 (shl 3)
%define SELECTOR_DATA_REAL      0000000000010_0_00b ; index * 8 (shl 3)
%define SELECTOR_VIDEO          0000000000011_0_00b ; index * 8 (shl 3)
%define SELECTOR_CODE_KERNEL    0000000000100_0_00b
%define SELECTOR_DATA_KERNEL    0000000000101_0_00b
%define SELECTOR_CODE_USER      0000000000110_0_11b
%define SELECTOR_DATA_USER      0000000000111_0_11b

org LOADER_BASE_ADDR

; Note: Now, the ES contains the address of Video Buffer, we can use
; it directly.
_setup_32:

    call near _fetch_info_from_bios

    ; mov eax, KERNEL_START_SECTOR
    ; mov bx, KERNEL_BASE_ADDR
    ; mov cx, KERNEL_SECTOR_SIZE
    ; call _read_disk_lba

    call near _init_protect_mode

; Well, now's the time to actually move into protected mode. To make
; things as simple as possible, we do no register set-up or anything,
; we let the gnu-compiled 32-bit programs do that. We just jump to
; absolute address 0x10000(compiled from C), in 32-bit protected mode.
; 2022/11/11,11:15pm: I implemented LBA48 to read hard disk, but
; floppy reading is still a problem. So I temporarily use a disk to
; configure the Bochs.

; We may not need this, I think. But I haven't tested it.
    ; push __unreachable

	mov	eax, cr0
    or eax, 1 ; The first bit stands for whether the PE is enabled or not.
    mov cr0, eax ; That's it!!

; Note: the 'main' label is just a test for protect mode. Actually,
; in the following steps, we should turn to the code compiled by g++
; which is written in C programming language.

; TODO
; I don't want to reprogram the interrupt and the ugliest code to 
; interact with the disk(floppy maybe), so I think I should load the
; kernel before we put the first bit of cr0 to 1.

    ; jmp dword SELECTOR_CODE_REAL:0x10000
    jmp dword SELECTOR_CODE_REAL:main ; Fixed error: gate descriptor is not valid sys reg (vector=0x0d / vector=0x08)

__unreachable:
    hlt
    jmp __unreachable

; bits 16
;---------------------------------------------------------
; Toggle the graphic mode to VGA (320*200*8-bit rainbow)
_enable_vga_320_200_8:
    mov ah, 0x00
    mov al, 0x13
    int 0x10

;---------------------------------------------------------
; This routine is responsible to read some informations from the BIOS, e.g.
; the size of memory and the disk info.
_fetch_info_from_bios:

; Note: When getting memory size from bios via 0x15 (ax=0xe801) interrupt,
; the returned size (in ax) is always smaller for 1mB than the real size, 
; because of some historical problem (e.g. ISA equipment)
._get_mem_size:
    mov ax, 0xe801
    int 0x15
    jc ._get_mem_size
    mov word [MEMORY_TABLE_LOW_MEM], ax
    mov word [MEMORY_TABLE_HIGH_MEM], bx
    cmp bx, 0
    jz ._end_get_mem_size
; If bx != 0, it means that WE HAVE MORE THAN 16MB MEMORY, so we can simply
; set ax to 0x4000 cuz it's the correct size that we have.
    mov word [MEMORY_TABLE_HEAD], 0x4000
._end_get_mem_size:

._calc_mem_size:
; calc memory
    xor ecx, ecx
    xor eax, eax
    xor ebx, ebx
; step 1: calc low 16mb memory
    mov ax, word [MEMORY_TABLE_LOW_MEM]
    mov ebx, 1024
    mul ebx
    mov ecx, eax
; step 2: calc high 4gb memory
    mov ax, word [MEMORY_TABLE_HIGH_MEM]
    mov ebx, 64
    mul ebx
    mov ebx, 1024
    mul ebx
    add ecx, eax
; finish
    mov dword [MEMORY_TABLE_CALCED_SIZE], ecx
._end_calc_mem_size:

._get_disk_info:

    push esi
    push edi

    xor eax, eax
    xor esi, esi
    xor edi, edi
    xor edx, edx
    xor ecx, ecx

    mov ah, 8
    mov dl, [BOOT_DRIVE]
    int 0x13

    mov [BOOT_DRIVE_INFO_TYPE], bl

    mov [BOOT_DRIVE_INFO_MAX_SECTORS], cl
    and word [BOOT_DRIVE_INFO_MAX_SECTORS], 00111111b

    mov [BOOT_DRIVE_INFO_MAX_CYLINDERS], ch
    and cl, 11000000b
    shr cl, 6
    mov ch, cl
    mov cl, [BOOT_DRIVE_INFO_MAX_CYLINDERS]
    mov dword [BOOT_DRIVE_INFO_MAX_CYLINDERS], ecx

    mov [BOOT_DRIVE_INFO_MAX_HEADS], dh

    pop edi
    pop esi
._end_get_disk_info:
._get_keyboard_leds:
    mov ah, 0x02
    int 0x16
    mov byte [KEYBOARD_LEDS_INFO], al
._end_get_keyboard_leds:

    retn

;----------------------------------------------------------------
_interrutp_13H_bios:
    ; Deprecated cuz we use LBA48 now
    mov ah, 0x02
    int 0x13

    retn

;----------------------------------------------------------------
_init_protect_mode:
    cli     ; no interrupts is allowed!

; load gdtr
    lgdt [gdtr_value]

; now we enable A20
    call near _enable_A20
    ; in al, 0x92
    ; or al, 0000_0010b
    ; out 0x92, al

    retn

;-----------------------------------------------------------------
_enable_A20:

	call	near _empty_8042
	mov	al, 0xD1		; command write
	out	0x64,al
	call	near _empty_8042
	mov	al, 0xDF		; A20 on
	out	0x60, al
	call	near _empty_8042

    retn

;------------------------------------------------------------------
; This routine checks that the keyboard command queue is empty
; No timeout is used - if this hangs there is something wrong with
; the machine, and we probably couldn't proceed anyway.
_empty_8042:
	dd	0x00eb,0x00eb
	in	al, 0x64	; 8042 status port
	test al, 2		; is input buffer full?
	jnz	_empty_8042	; yes - loop
	retn

;----------------------------------------------------------
; simple GDT for the early period of the initialization of the 
; kernel. We've got a Code, a Data and another Data for Video.
gdt:
_desc_nil:
; 0 descriptor
	dd  0x00000000		; dummy
    dd  0x00000000
_desc_code_real:
; 1 descriptor: 4GB-text-descriptor
    dd  0000000000000000_1111111111111111b          ; base: 00000000_00000000_00000000_00000000
    dd  00000000_0_1_0_0_1111_1_00_1_1010_00000000b ; limit: 1111_1111_1111_1111_1111
_desc_data_real:
; 2 descriptor: 4GB-data-descriptor
    dd  0000000000000000_1111111111111111b          ; base: 00000000_00000000_00000000_00000000
    dd  00000000_0_0_0_0_1111_1_00_1_0010_00000000b ; limit: 1111_1111_1111_1111_1111
_desc_video:
; 3 descriptor: 28kb-video-sector-descriptor
    dd  1000000000000000_1111111111111111b          ; base: 00000000_00001011_10000000_00000000
    dd  00000000_0_1_0_0_1111_1_00_1_0010_00001011b ; limit: 1111_1111_1111_1111_1111
_desc_code_kernel:
; 4 descriptor: 2gB-kernel-code-descriptor
    dd  0000000000000000_1111111111111111b          ; base: 10000000_00000000_00000000_00000000
    dd  10000000_1_1_0_0_0111_1_00_1_1010_00000000b ; limit: 0111_1111_1111_1111_1111 * 4096
_desc_data_kernel:
; 5 descriptor: 2gB-kernel-data-descriptor
    dd  0000000000000000_1111111111111111b          ; base: 10000000_00000000_00000000_00000000
    dd  10000000_1_0_0_0_0111_1_00_1_0010_00000000b ; limit: 0111_1111_1111_1111_1111 * 4096
_desc_code_user:
; 6 descriptor: 2gB-user-code-descriptor
    dd  0000000000000000_1111111111111111b          ; base: 00000000_00000001_00000000_00000000
    dd  00000000_1_1_0_0_0111_1_11_1_1010_00000001b ; limit: 0111_1111_1111_1111_1111 * 4096
_desc_data_user:
; 7 descriptor: 2gB-user-data-descriptor
    dd  0000000000000000_1111111111111111b          ; base: 00000000_00000001_00000000_00000000
    dd  00000000_1_0_0_0_0111_1_11_1_0010_00000001b ; limit: 0111_1111_1111_1111_1111 * 4096
gdt_end:

gdtr_value:
	dw	gdt_end - gdt - 1
	dd  gdt

max_cylinders:
    dw  0
max_sectors:
    dw  0
max_heads:
    dw  0

;-----------------------------------------------
; Now we are in the protect mode, with a super simple GDT loaded.
; Code Segment is marked as 32-bit, so we let NASM compile 32-bit
; code for us.
;-----------------------------------------------
    [bits 32]
main:
    mov eax, SELECTOR_DATA_REAL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov eax, SELECTOR_VIDEO
    mov gs, ax

    push str_
    call _vprint_cover

    push 4 ; sectors
    push 0 ; heads
    push 0 ; cylinders
    call _covert_chs_to_lba

; eax is already initialized
    mov ebx, 0x10000
    mov ecx, 200
    call _read_disk_lba  

    jmp SELECTOR_CODE_REAL:0x10000

;----------------------------------------------------------------
; A simple function to print a string. It will print the str
; to the top of the screen, covering the remaining chars on the
; screen.
;
; Note: In 32-bit mode, as tradition, we use stack to pass the 
; param. However, when CPU executes "call" instruction, it pushes 
; the return address to the top of stack, so I have to store the
; address in the EBX registers, and pushes it back to the stack
; before the function returns.
; Then this function will load the address of the head of the str
; to the EDX register, and use ECX to enum the chars. It won't
; stop printing until meets "null" char. Consequently, make sure
; that the string passed is ended by a '\0' char, as the example
; "str_" defined.
_vprint_cover:
    pop ebx ; restore the return address.
            ; It's ugly, but I haven't got a better method FUCK YOU INTEL :-(
    pop edx ; now the stack-top is string, just pop it

    push eax ; store eax, cuz it will be used to store the char temply next
    xor ecx, ecx ; ecx<-0

._put_char:
    mov eax, [edx] ; read one char
    cmp eax, 0     ; if the char is '\0', then return
    jz ._ret

    ; al is the char in ascii
    mov byte [gs:ecx], al ; show char
    mov byte [gs:ecx+1], 0x07 ; printing style

    add ecx, 2 ; In VGA Text Mode, we use 2 bytes for showing a char
    inc edx ; Then we jump to print the next char
    jmp ._put_char

._ret:
    pop eax ; restore eax
    push ebx ; EBX contains the address to which cpu returns.
    ret

; int _covert_chs_to_lba(int c, int h, int s);
_covert_chs_to_lba:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    mov ecx, 16
    mul ecx
    add eax, [ebp+12]
    mov ecx, 64
    mul ecx
    add eax, [ebp+16]
    dec eax

    pop ebp
    ret

;-------------------------------------------------------
; eax=LBA start sector num.
; ebx=dest addr
; ecx=sector num.
_read_disk_lba:

    push eax
    mov edx, 0x1f1
    mov al, 0
    out dx, al
    out dx, al
    pop eax
;------
    inc dx
    push eax
    mov al, ch
    out dx, al
    mov al, cl
    out dx, al      ; Write 0x1f2: 1. high 8 bit of sector; 2. low 8 bit etc.
    pop eax
;-------
    inc dx

    push eax
    shr eax, 24
    out dx, al
    pop eax
    
    out dx, al      ; Write 0x1f3: 1. 24-31 bit of LBA argument; 2. 0-7 bit etc.
;-------
    inc dx

    push eax
    mov al, 0
    out dx, al
    pop eax

    push eax
    mov al, ah
    out dx, al      ; Write 0x1f4: 1. 32-39 bit(unused); 2. 8-15 bit;
    pop eax
;-------
    inc dx

    push eax
    mov al, 0
    out dx, al
    pop eax

    shr eax, 16
    out dx, al      ; Write 0x1f5: 1. 40-47 bit(unused); 2. 16-23 bit;
;-------
    inc dx
    mov al, 0x40 ; lba48-0x40; lba28-0xe0
    out dx, al
;-------
    inc dx
    mov al, 0x24 ;lba48-0x24;lba24-0x20
    out dx, al
;-------
    mov dx, 0x1f7
._wait_for_disk:
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz ._wait_for_disk

    mov eax, ecx
    mov ecx, 256
    mul ecx
    mov ecx, eax
    mov dx, 0x1f0
._rep_to_read:
    in ax, dx
    mov word [ebx], ax
    add ebx, 2
    loop ._rep_to_read

    ret

str_: db "Loaded Kernel in Protected Mode.",0

times 1024-($-$$) db 0x0