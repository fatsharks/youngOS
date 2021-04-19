; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               kernel.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                     Forrest Yu, 2005
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; ----------------------------------------------------------------------
; 编译连接方法:
; $ rm -f kernel.bin
; $ nasm -f elf -o kernel.o kernel.asm
; $ nasm -f elf -o string.o string.asm
; $ nasm -f elf -o klib.o klib.asm
; $ gcc -c -o start.o start.c
; $ ld -s -Ttext 0x30400 -o kernel.bin kernel.o string.o start.o klib.o
; $ rm -f kernel.o string.o start.o
; $ 
; ----------------------------------------------------------------------

; 新建了一个段选择子，偏移为8，属性为0，表示位ring0段的选择子
SELECTOR_KERNEL_CS	equ	8	

; 导入函数
extern	cstart

; 导入全局变量
extern	gdt_ptr

; （Block Started by Symbol）通常是指用来存放程序中未初始化的全局变量和静态变量的一块内存区域
; 注意和数据段的区别，BSS存放的是未初始化的全局变量和静态变量，数据段存放的是初始化后的全局变量和静态变量
[SECTION .bss]
StackSpace		resb	2 * 1024; resb设计用在模块的 BSS 段中：它们声明未初始化的存储空间。每一个带有单个操作数，用来表明字节数，字数，或双字数或其它的需要保留单位。
StackTop:		; StackTop是一个标记（LABEL），用来指示当前的段内偏移地址
; 这是一个2KB大小的堆栈段，段基址在StackSpace标记处，栈顶在StackSpace + 2KB处，即StackTop标记所指的地方，BSS段从下向上增长

[section .text]	; 代码在此

global _start	; 导出 _start

_start:
	; 此时内存看上去是这样的（更详细的内存情况在 LOADER.ASM 中有说明）：
	;              ┃                                    ┃
	;              ┃                 ...                ┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■Page  Tables■■■■■■┃
	;              ┃■■■■■(大小由LOADER决定)■■■■┃ PageTblBase
	;    00101000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■Page Directory Table■■■■┃ PageDirBase = 1M
	;    00100000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□ Hardware  Reserved □□□□┃ B8000h ← gs
	;       9FC00h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■LOADER.BIN■■■■■■┃ somewhere in LOADER ← esp
	;       90000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■KERNEL.BIN■■■■■■┃
	;       80000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■KERNEL■■■■■■■┃ 30400h ← KERNEL 入口 (KernelEntryPointPhyAddr)
	;       30000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┋                 ...                ┋
	;              ┋                                    ┋
	;           0h ┗━━━━━━━━━━━━━━━━━━┛ ← cs, ds, es, fs, ss
	;
	;
	; GDT 以及相应的描述符是这样的：
	;
	;		              Descriptors               Selectors
	;              ┏━━━━━━━━━━━━━━━━━━┓
	;              ┃         Dummy Descriptor           ┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃         DESC_FLAT_C    (0～4G)     ┃   8h = cs
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃         DESC_FLAT_RW   (0～4G)     ┃  10h = ds, es, fs, ss
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃         DESC_VIDEO                 ┃  1Bh = gs
	;              ┗━━━━━━━━━━━━━━━━━━┛
	;
	; 注意! 在使用 C 代码的时候一定要保证 ds, es, ss 这几个段寄存器的值是一样的
	; 因为编译器有可能编译出使用它们的代码, 而编译器默认它们是一样的. 比如串拷贝操作会用到 ds 和 es.
	;
	;


	; 把 esp 从 LOADER 挪到 KERNEL
	mov	esp, StackTop	; 堆栈在 bss 段中 完成堆栈的切换

	sgdt	[gdt_ptr]	; 存储全局描述符表
	call	cstart		; 在此函数中改变了gdt_ptr，让它指向新的GDT
	lgdt	[gdt_ptr]	; 使用新的GDT

	;lidt	[idt_ptr]

	jmp	SELECTOR_KERNEL_CS:csinit	
	;TODO:程序执行中，段选择子被加载到 cs 寄存器中，除非进行长跳转，否则 cs 寄存器的值是不会发生变化的。我们虽然通过上面的指令实现了 gdtr 寄存器的更新，但我们紧接着必须通过长跳转把新的段选择子更新到 cs 寄存器中
csinit:		; “这个跳转指令强制使用刚刚初始化的结构”

	push	0
    popfd    ; 将esp指向的栈顶对应的数据弹到标志寄存器eflags
	; push 0和popfd完成将标志寄存器清零

    hlt      ; 使程序停止运行，处理器进入暂停状态，不执行任何操作，不影响标志。