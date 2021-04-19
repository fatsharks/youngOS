
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            start.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "tty.h"
#include "console.h"
#include "string.h"
#include "proc.h"
#include "global.h"
#include "proto.h"

//一共48个字节，只修改了段基址和段界限，没有改变属性
// PUBLIC	u8		gdt_ptr[6];	/* 0~15:Limit  16~47:Base */
// PUBLIC	DESCRIPTOR	gdt[GDT_SIZE];	//新的GDT

PUBLIC void cstart()
{

	disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
			 "-----\"cstart\" begins-----\n");

	/* 将 LOADER 中的 GDT 复制到新的 GDT 中 */
	memcpy(&gdt,							  /* New GDT */
		   (void *)(*((u32 *)(&gdt_ptr[2]))), /* Base  of Old GDT */
		   *((u16 *)(&gdt_ptr[0])) + 1		  /* Limit of Old GDT */
	);
	/* gdt_ptr[6] 共 6 个字节：0~15:Limit  16~47:Base。用作 sgdt/lgdt 的参数。*/
	//定义两个指针分别指向段基址和段界限
	u16 *p_gdt_limit = (u16 *)(&gdt_ptr[0]); //p_gdt_limit,并指向gdt_ptr[0]这个地址－段界限
	u32 *p_gdt_base = (u32 *)(&gdt_ptr[2]);	 //p_gdt_base，指向gdt_ptr[2]这个地址－段基址
	//分别给两个指针赋值，改变基址和段界限，指向了新的GDT表
	*p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
	*p_gdt_base = (u32)&gdt;

	/* gdt_ptr[6] 共 6 个字节：0~15:Limit  16~47:Base。用作 sidt/lidt 的参数。*/
	// 具体参数机用法同上
	u16 *p_idt_limit = (u16 *)(&idt_ptr[0]);
	u32 *p_idt_base = (u32 *)(&idt_ptr[2]);
	*p_idt_limit = IDT_SIZE * sizeof(GATE) - 1;
	*p_idt_base = (u32)&idt;

	init_prot();

	disp_str("-----\"cstart\" endss-----\n");
}
