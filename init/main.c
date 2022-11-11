/*
                Copyright (C) 2022 SagiriXiguajerry

 We are in Protect Mode now, and a simple gdt is loaded. Then we need
 to initialize our kernel.
*/

#include <main.h>
#include <paging.h>

bool started = false;

void kernel_main(void) {
_init_kernel_:
    if (started) {
        hlt();
        goto _init_kernel_;
    }
    started = true;
    for (;;) ;
    // sti();
}

