
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            main.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "string.h"
#include "proc.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "proto.h"

/*======================================================================*
                            kernel_main
 *======================================================================*/
PUBLIC int kernel_main()
{
	disp_str("-----\"kernel_main\" begins-----\n");

	PROCESS *p_proc = proc_table;
	TASK *p_task = task_table;
	char *p_task_stack = task_stack + STACK_SIZE_TOTAL;

	u16 selector_ldt = SELECTOR_LDT_FIRST;
	u8 priviliege, rpl;
	int eflags;
	int prio;

	for (int i = 0; i < NR_TASKS + NR_PROCS; i++)
	{
		if (i < NR_TASKS)
		{
			p_task = task_table + i;
			priviliege = PRIVILEGE_TASK;
			rpl = RPL_TASK;
			eflags = 0x1202;
			prio = 15;
		}
		else
		{
			p_task = user_proc_table + (i - NR_TASKS);
			priviliege = PRIVILEGE_USER;
			rpl = RPL_USER;
			eflags = 0x202;
			prio = 5;
		}
		
		
		strcpy(p_proc->p_name, p_task->name);
		p_proc->pid = i;
		p_proc->ldt_sel = selector_ldt;

		/*将两个局部描述符分别复制到对应PCB指针位置*/
		/*选择子高13位为索引值，中间为TI位，低两位为RPL．所以右移3位*/
		memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
		memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));

		/*设置两个局部描述符的属性值和特权级（代码段和数据段）*/
		/*描述符的6　7位表示DPL,特权级．所以左移5位*/
		p_proc->ldts[0].attr1 = DA_C | priviliege << 5;	  // change the DPL
		p_proc->ldts[1].attr1 = DA_DRW | priviliege << 5; // change the DPL

		/*一个描述符8个字节，所以　0　8分别对应前两个描述符*/
		/*寄存器中存放的是描述符对应的选择子*/
		p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
		p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
		p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
		p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
		p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
		p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | rpl; //指向显存

		p_proc->regs.eip = (u32)p_task->initial_eip;
		p_proc->regs.esp = (u32)p_task_stack;
		p_proc->regs.eflags = eflags;

		p_proc->nr_tty = 0;

		p_proc->p_flags = 0;
		p_proc->p_msg = 0;
		p_proc->p_recvfrom = NO_TASK;
		p_proc->p_sendto = NO_TASK;
		p_proc->has_int_msg = 0;
		p_proc->q_sending = 0;
		p_proc->next_sending = 0;

		p_proc->ticks = p_proc->priority = prio;
		p_task_stack -= p_task->stacksize;
		//p_task_stack减去本进程堆栈的大小，使之指向下一个进程的堆栈底
		p_proc++;
		p_task++;
		selector_ldt += 1 << 3;
		//选择子第三位式TI和RPL,索引值+1需要左移3位
	}


	proc_table[NR_TASKS + 1].nr_tty = 0;
    proc_table[NR_TASKS + 2].nr_tty = 1;
    proc_table[NR_TASKS + 3].nr_tty = 1;
	/*初始化PCB块中的局部描述符表选择子*/
	// p_proc->ldt_sel	= SELECTOR_LDT_FIRST;

	/* eip指向TestA，这表明进程将从TestA的入口地址开始运行，函数名就是一个函数指针常量，指向函数入口地址 */
	// p_proc->regs.eip = (u32)TestA;

	/* esp指向单独的堆栈，堆栈大小为STACK_SIZE_TOTAL */
	/* 在汇编中C语言的变量名表示一段内存空间的起始地址，esp指向堆栈的栈顶，因此应该加上内存空间大小，指向数组的末尾元素地址 */
	// p_proc->regs.esp = (u32)task_stack + STACK_SIZE_TOTAL;

	/* eflags=0x1202,恰巧设置了IF位，并把IOPL设为1，这样，进程就可以使用I/O指令，并且中断会在iretd执行时，被打开 */
	// p_proc->regs.eflags = 0x1202; // IF=1, IOPL=1, bit 2 is always 1.

	k_reenter = 0;
	ticks = 0;

	//先进入的restart部分，需要k_reenter自减1,所以赋初值0
	p_proc_ready = proc_table;

	init_clock();
	init_keyboard();

	/* 清空屏幕 */
	// disp_pos = 0;
	// for (int i = 0; i < 80 * 25; i++)
	// {
	// 	disp_str(" ");
	// }
	// disp_pos = 0;

	restart();

	while (1)
	{
	}
}

/*****************************************************************************
 *                                get_ticks
 *****************************************************************************/
PUBLIC int get_ticks()
{
	MESSAGE msg;
	reset_msg(&msg);
	msg.type = GET_TICKS;
	send_recv(BOTH, TASK_SYS, &msg);
	return msg.RETVAL;
}

/*======================================================================*
                               TestA
 *======================================================================*/
void TestA()
{
	int i = 0;
	while (1)
	{
		// get_ticks();
		// disp_color_str("A.", BRIGHT | MAKE_COLOR(BLACK, RED));
		// disp_int(get_ticks());
		printf("<ticks: %x>", get_ticks());
		milli_delay(200);
		// disp_str(".");
		// delay(1);
	}
}

void TestB()
{
	int i = 0x1000;
	while (1)
	{
		// disp_color_str("B.", BRIGHT | MAKE_COLOR(BLACK, RED));
		// disp_int(get_ticks());
		printf("B");
		milli_delay(200);
		// disp_str(".");
	}
}

void TestC()
{
	int i = 0x2000;
	while (1)
	{
		// disp_color_str("C.", BRIGHT | MAKE_COLOR(BLACK, RED));
		// disp_int(get_ticks());
		printf("C");
		milli_delay(200);
		// disp_str(".");
	}
}

/*****************************************************************************
 *                                panic
 *****************************************************************************/
PUBLIC void panic(const char* fmt, ...)
{
	int i;
	char buf[256];

	var_list arg = (var_list)((char*)&fmt + 4);

	i = vsprintf(buf, fmt, arg);

	printl("%c !!panic!! %s", MAG_CH_PANIC, buf);

	__asm__ __volatile__("ud2");

}