/*
 *         Copyright   (C) 2022 SagiriXiguajerry
 */

#include "kernel.h"

int add(int i) {
    return i + 1;
}

void kernel_main(void) {
    for (;;) {
        int i = add(1);
        hlt();
    }
}
