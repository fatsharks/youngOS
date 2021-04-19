#########################
# Makefile for Orange'S #
#########################

# Entry point of Orange'S
# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT	= 0x30400

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET	=   0x400

# Programs, flags, etc.
ASM		= nasm
DASM	= ndisasm
CC		= gcc
LD		= ld
ASMBFLAGS	= -I boot/include/
ASMKFLAGS	= -f elf -g -F stabs -I include/
ASMLFLAGS	= -f elf -g -F stabs -I include/
CFLAGS		= -I include/ -m32 -c -fno-builtin
LDFLAGS		= -m elf_i386 -Ttext $(ENTRYPOINT)
DASMFLAGS	= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# This Program
ORANGESBOOT	= boot/boot1.bin boot/loader.bin
ORANGESKERNEL	= kernel/kernel.bin
OBJS		= kernel/kernel.o kernel/syscall.o kernel/proc.o kernel/start.o kernel/main.o kernel/keyboard.o kernel/i8259.o kernel/global.o kernel/protect.o kernel/clock.o kernel/tty.o kernel/printf.o kernel/vsprintf.o kernel/console.o lib/klib.o lib/kliba.o lib/string.o 
DASMOUTPUT	= kernel.bin.asm

# All Phony Targets
.PHONY : everything final image clean realclean disasm all buildimg

# Default starting position
everything : $(ORANGESBOOT) $(ORANGESKERNEL)

all : realclean everything

final : all clean

image : final buildimg

clean :
	rm -f $(OBJS)

realclean :
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

disasm :
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)

# We assume that "a.img" exists in current folder
buildimg :
	dd if=boot/boot1.bin of=boot.img bs=512 count=1 conv=notrunc
	sudo mount -o loop boot.img /mnt/floppy/
	sudo cp -fv boot/loader.bin /mnt/floppy/
	sudo cp -fv kernel/kernel.bin /mnt/floppy
	sudo umount /mnt/floppy

boot/boot1.bin : boot/boot1.asm boot/include/load.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader2.asm boot/include/load.inc \
			boot/include/fat12hdr.inc boot/include/pm.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

$(ORANGESKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $(ORANGESKERNEL) $(OBJS)

kernel/kernel.o : kernel/kernel8.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/syscall.o : kernel/syscall.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/type.h include/const.h include/protect.h include/proto.h include/string.h include/global.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/i8259.o : kernel/i8259.c include/type.h include/const.h include/protect.h include/proto.h
	$(CC) $(CFLAGS) -o $@ $<
	
kernel/main.o : kernel/main.c include/type.h include/const.h include/protect.h include/proto.h include/string.h include/proc.h include/global.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/clock.o : kernel/clock.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/global.o : kernel/global.c include/global.h include/proto.h include/type.h include/const.h include/proc.h include/protect.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/proc.o : kernel/proc.c include/proc.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/keyboard.o : kernel/keyboard.c
	$(CC) $(CFLAGS) -fno-stack-protector -o $@ $<

kernel/tty.o : kernel/tty.c
	$(CC) $(CFLAGS) -fno-stack-protector -o $@ $<

kernel/console.o : kernel/console.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/printf.o : kernel/printf.c
	$(CC) $(CFLAGS) -fno-stack-protector -o $@ $<

kernel/vsprintf.o : kernel/vsprintf.c
	$(CC) $(CFLAGS) -fno-stack-protector -o $@ $<

kernel/protect.o : kernel/protect.c include/type.h include/const.h include/protect.h include/proto.h include/proc.h include/global.h
	$(CC) $(CFLAGS) -fno-stack-protector -o $@ $<
 
lib/klib.o : lib/klib.c include/type.h include/const.h include/protect.h include/proc.h include/proto.h include/string.h include/global.h
	$(CC) $(CFLAGS) -fno-stack-protector -o $@ $<

lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMLFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASMLFLAGS) -o $@ $<
