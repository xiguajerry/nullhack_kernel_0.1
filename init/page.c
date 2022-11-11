void enable_paging(void) {
    __asm__ (
        ".intel_syntax noprefix\n"
        "mov eax, cr0\n"
        "or eax, 0x80000000\n"
        "mov cr0, eax"
    );
    return;
}