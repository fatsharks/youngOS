; ==========================================
; pmtest1.asm
; 编译方法：nasm pmtest1.asm -o pmtest1.bin
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明

org	0100h ;org 汇编伪指令，从何处开始执行
	jmp	LABEL_BEGIN ;jmp不改变CS，一直为0100h

[SECTION .gdt]
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   Descriptor       0,                0, 0           ; 空描述符
LABEL_DESC_CODE32: Descriptor       0, SegCode32Len - 1, DA_C + DA_32; 非一致代码段
LABEL_DESC_VIDEO:  Descriptor 0B8000h,           0ffffh, DA_DRW	     ; 显存首地址
;为了加快读取和输出速度，显存是直接映射在处理器能处理的内存中的（而不需要和显卡的外围接口打交道），也就是内存空间，通常情况下常规内存是占用8086处理器的前640KB（也就是0x00000-0x9FFFF），BIOS-ROM占用最顶端的64KB(（地址0xF0000-0xFFFFF），中间还有320KB的空间，其中0xB8000-0xBFFFF这段空间就是给显卡的，每一次显卡加电自检的时候，都会把自己初始化80*25的文本模式，屏幕上可以显示25行，每一行80个字符，一共2000个字符。
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限　GdtPtr-地址所代表的变量或者标签
		dd	0		; GDT基地址　没有标签，表示紧挨着上一个存放

; GDT 选择子
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT;可以简单理解为基址偏移
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]

[SECTION .s16]
[BITS	16];表示是16位的
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; 初始化 32 位代码段描述符
	; 修改了只修改了段基址，分别是２、３、　４　７字节
	xor	eax, eax; xor－异或指令，将eax清零
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32;获得32位代码段基址，绝对地址
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0;第０位为PE位，为0表示运行于实模式，为1表示运行于保护模式
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs,
					; 并跳转到 Code32Selector:0  处
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]

LABEL_SEG_CODE32:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的) gs－没有特定用途的段寄存器

	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			;ah-0ch-表示写入图形像素 0000: 黑底    1100: 红字
	mov	al, 'P'			;al-写入的字符
	mov	[gs:edi], ax

	; 到此停止
	jmp	$

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]
