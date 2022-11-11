AS := nasm
LD := ld
CC := gcc
OBJCPY := objcopy

CFLAGS += -Wall -Wno-format -Wno-unused
CFLAGS += -std=gnu99 -static -m32
CFLAGS += -I../include -I../include/kernel
CFLAGS += -ffunction-sections -nostdlib -nostdinc -fno-builtin -ffreestanding
CFLAGS += -fno-pie
CFLAGS += -masm=intel

all: main.o page.o
	
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf ./**.out
	rm -rf ./**.bin
	rm -rf ./**.o