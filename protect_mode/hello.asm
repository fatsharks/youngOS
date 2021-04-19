; 编译链接方法
; (ld 的‘-s’选项意为“strip all”)
;
; $ nasm -f elf hello.asm -o hello.o
; $ ld -s hello.o -o hello
; $ ./hello
; Hello, world!
; $

[section .data]	; 数据在此

strHello	db	"Hello, world!", 0Ah
STRLEN		equ	$ - strHello

[section .text]	; 代码在此

global _start	; 我们必须导出 _start 这个入口，以便让链接器识别,linux寻找这个 _start标签作为程序的默认进入点

_start:
	mov	edx, STRLEN
	mov	ecx, strHello
	mov	ebx, 1
	mov	eax, 4		; sys_write
					; 0x80调用之前eax寄存器值为4，ebx为文件描述符，stdout的文件描述符为1，ecx则为buffer的内存地址，edx为buffer长度
	int	0x80		; 系统调用,从用户态进入了内核态，SS、ESP、eflags、CS、EIP五个寄存器自动压入内核堆栈
	mov	ebx, 0		; 0
	mov	eax, 1		; sys_exit，相当于exit(0)
	int	0x80		; 系统调用
