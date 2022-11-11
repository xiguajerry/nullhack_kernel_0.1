#ifndef _H_MAIN
#define _H_MAIN

#include <stddef.h>

#define sti() __asm__ ("sti");


#define cli() __asm__ ("cli");

#define hlt() __asm__ ("hlt");

#define LGDT(SOURCE) {\
__asm__ ("lgdt (%0)" \
        : \
        : "m" (SOURCE) \
        : "gdtr")\
};

#define LIDT(SOURCE) {\
__asm__ ("lidt (%0)" \
        : \
        : "m" (SOURCE) \
        : "idtr") \
};

// void show_msg(void);

void kernel_main(void);

#endif