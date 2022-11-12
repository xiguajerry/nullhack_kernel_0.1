#include <paging.h>

void enable_paging(void) {
    

    __asm__ (
        "movl %cr0, %eax\n"
        "orl $0x80000000, %eax\n"
        "movl %eax, %cr0\n"
    );
    return;
}