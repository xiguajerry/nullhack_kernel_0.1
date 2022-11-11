AS := nasm
LD := ld
CC := gcc
OBJCPY := objcopy

CFLAGS += -Wall -Wno-format -Wno-unused
CFLAGS += -std=gnu99 -static -m32
CFLAGS += -I./include
CFLAGS += -ffunction-sections -nostdlib -nostdinc -fno-builtin -ffreestanding
CFLAGS += -fno-pie

LDFLAGS += -m elf_i386 --oformat binary -Ttext=0x10000 -e kernel_main

all: clean main.bin boot.bin run
	bximage -mode=create -hd=16 -q "./run/a.img"
	dd if=./boot/entry.bin of=./run/a.img conv=notrunc
	dd if=./boot/setup.bin of=./run/a.img seek=1 bs=512 count=2 conv=notrunc
	dd if=./init/main.bin of=./run/a.img seek=3 bs=512 count=200 conv=notrunc

main.bin: main
	$(LD) $(LDFLAGS) ./init/main.o ./init/page.o -o ./init/main.bin

main:
	(cd ./init; make)

boot.bin:
	(cd ./boot; make)

run:
	(cd ./run; make)

clean:
	(cd ./init; make clean)
	(cd ./boot; make clean)
	(cd ./run; make clean)