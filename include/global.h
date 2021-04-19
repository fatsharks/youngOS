
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            global.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* EXTERN is defined as extern except in global.c */
#ifndef _ORANGES_GLOBAL_H_
#define _ORANGES_GLOBAL_H_
#ifdef	GLOBAL_VARIABLES_HERE
#undef	EXTERN
#define	EXTERN
#endif

//TODO:不用包含的原因可能是头文件的前置声明
EXTERN	int		disp_pos;
EXTERN	u8		gdt_ptr[6];	/* 0~15:Limit  16~47:Base */
EXTERN	DESCRIPTOR	gdt[GDT_SIZE];
EXTERN	u8		idt_ptr[6];	/* 0~15:Limit  16~47:Base */
EXTERN	GATE		idt[IDT_SIZE];
EXTERN  TSS     tss;
EXTERN  PROCESS*    p_proc_ready;/*指向就绪队列的首进程*/
EXTERN  u32     k_reenter;
EXTERN  int     ticks;
EXTERN  int     nr_current_console;

extern  TASK        task_table[];
extern  TASK        user_proc_table[];
extern  PROCESS     proc_table[];
extern  char        task_stack[];
extern  system_call sys_call_table[];
extern  irq_handler irq_table[];
extern  TTY     tty_table[];
extern  CONSOLE console_table[];

#endif