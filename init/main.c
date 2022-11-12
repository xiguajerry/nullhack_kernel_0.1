/*
                Copyright (C) 2022 SagiriXiguajerry

 We are in Protect Mode now, and a simple gdt is loaded. Then we need
 to initialize our kernel.
*/

void _entry(void) {
    __asm__ volatile("jmp kernel_main");
}

#include <main.h>
#include <paging.h>
#include <vsprintf.h>

#define SAFE_CAST(dest, src) ((dest)((char *) src))

bool started = false;

char booting_message[64];

int sprintf(char * str, const char *fmt, ...);

void kernel_main(void) {
_init_kernel_:
    if (started) {
        hlt();
        goto _init_kernel_;
    }
    started = true;
    // recalc the memory size
    size_t memory_bytes = 0;
    int memory_low_16 = *SAFE_CAST(int *, MEMORY_TABLE_LOW_MEM);
    int memory_high_64 = *SAFE_CAST(int *, MEMORY_TABLE_HIGH_MEM);
    memory_bytes += memory_low_16*1024;
    memory_bytes += memory_high_64*64*1024;
    *SAFE_CAST(size_t *, MEMORY_TABLE_CALCED_SIZE) = memory_bytes;
    sprintf(booting_message, "Boot from C,Memory:%lumb.         ", memory_bytes / 1024 / 1024);
    // *((char *) 0xb8000) = 'F';
    print_covering(booting_message);
    for (;;) ;
    // sti();
}

int sprintf(char * str, const char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	i = vsprintf(str, fmt, args);
	va_end(args);
	return i;
}