TOOLPREFIX = riscv64-linux-gnu-
CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb -gdwarf-2
CFLAGS += -fno-builtin-putchar
CFLAGS += -fno-pie -no-pie
CFLAGS += -mcmodel=medany

kernel: main.o entry.o
	$(LD) -T link.ld -o kernel entry.o main.o
	$(OBJDUMP) -S kernel > kernel.asm

clean:
	rm kernel
	rm *.o	