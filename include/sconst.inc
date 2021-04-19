
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               sconst.inc
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                     Forrest Yu, 2005
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;TSS中各个寄存器在堆栈中的偏移
P_STACKBASE	equ	0
GSREG		equ	P_STACKBASE
FSREG		equ	GSREG		+ 4
ESREG		equ	FSREG		+ 4
DSREG		equ	ESREG		+ 4
EDIREG		equ	DSREG		+ 4
ESIREG		equ	EDIREG		+ 4
EBPREG		equ	ESIREG		+ 4
KERNELESPREG	equ	EBPREG		+ 4
EBXREG		equ	KERNELESPREG	+ 4
EDXREG		equ	EBXREG		+ 4
ECXREG		equ	EDXREG		+ 4
EAXREG		equ	ECXREG		+ 4
RETADR		equ	EAXREG		+ 4
EIPREG		equ	RETADR		+ 4
CSREG		equ	EIPREG		+ 4
EFLAGSREG	equ	CSREG		+ 4
ESPREG		equ	EFLAGSREG	+ 4
SSREG		equ	ESPREG		+ 4
P_STACKTOP	equ	SSREG		+ 4
;TSS,ring0中的esp指向这里(restart中一开始对esp赋值相加).时钟中断时，从ring1到ring0，读取TSS中ring0中esp，指向进程表的这里,中断会把ring1 进程中的寄存器ss，esp，eflags，cs，ip 压入到进程表这里。向上压入
P_LDT_SEL	equ	P_STACKTOP  ;TODO:STACKTOP指向堆栈的最下方，即地址的最高处，跟BSS段的STACKTOP保持一致
P_LDT		equ	P_LDT_SEL	+ 4

TSS3_S_SP0	equ	4   ;TSS中esp0起始位置位于TSS堆栈的第五个字节

INT_M_CTL       equ 0x20
INT_M_CTLMASK   equ 0x21
INT_S_CTL       equ 0xA0
INT_S_CTLMASK   equ 0xA1

EOI             equ 0x20

; 以下选择子值必须与 protect.h 中保持一致!!!
SELECTOR_FLAT_C		equ		0x08	; LOADER 里面已经确定了的.
SELECTOR_TSS		equ		0x20	; TSS,从外层跳到内存时 SS 和 ESP 的值从里面获得.
SELECTOR_KERNEL_CS	equ		SELECTOR_FLAT_C 
