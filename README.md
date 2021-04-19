加载.bin文件
    dd if=bootc.bin of=pm.img bs=512 count=1 conv=notrunc
    sudo mount -o loop pm.img /mnt/floppy/
    sudo cp loader.bin /mnt/floppy/ -v
    sudo umount /mnt/floppy/

    floppya: 1_44=pm.img, status=inserted
    boot: floppy

加载.com文件
    sudo mount -o loop pm.img /mnt/floppy/
    sudo cp loader.com /mnt/floppy/
    sudo umount /mnt/floppy/

    floppya: 1_44=freedos.img, status=inserted
    floppyb: 1_44=pm.img, status=inserted
    boot: a

编译可执行文件-32位
    nasm -f elf -g -F stabs foo.asm -o foo.o
    gcc -m32 -fno-builtin -c bar.c -o bar.o
    ld -m elf_i386 foo.o bar.o -o foobar

加载kernel.bin到指定地址
    nasm -f elf -g -F stabs kernel.asm -o kernel.o
    ld -m elf_i386 -Ttext 0x30400 kernel.o -o kernel.bin

删除文件
    rm -f kernel.o string.o start.o