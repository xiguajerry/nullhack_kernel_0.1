all: a.img

a.img: entry.bin setup.bin
	bximage -mode=create -hd=16 -q "a.img"
	dd if=entry.bin of=a.img conv=notrunc
	dd if=setup.bin of=a.img seek=1 bs=512 count=2 conv=notrunc
	dd if=temp.txt of=a.img seek=3 bs=512 count=1 conv=notrunc

entry.bin:
	nasm entry.asm -o entry.bin

setup.bin:
	nasm setup.asm -o setup.bin

clean:
	rm a.img
	rm setup.bin
	rm entry.bin

run:
	bochs -f bochsrc