all: entry.bin setup.bin

entry.bin:
	nasm entry.asm -o entry.bin

setup.bin:
	nasm setup.asm -o setup.bin

clean:
	rm -rf ./**.out
	rm -rf ./**.bin
	rm -rf ./**.o