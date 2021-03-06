
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            proto.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* klib.asm */
PUBLIC void	out_byte(u16 port, u8 value);
PUBLIC u8	in_byte(u16 port);
PUBLIC void	disp_str(char * info);
PUBLIC void	disp_color_str(char * info, int color);

/* protect.c */
PUBLIC void	init_prot();
PUBLIC u32	seg2phys(u16 seg);

/* klib.c */
PUBLIC void	delay(int time);

/* kernel.asm */
void restart();

/* main.c */
void TestA();
void TestB();
void TestC();

/* i8259.c */
PUBLIC void put_irq_handler(int irq, irq_handler handler);
PUBLIC void spurious_irq(int irq);
PUBLIC void init_8259A();

/* clock.c */
PUBLIC void clock_handler(int irq);
PUBLIC void init_clock();
PUBLIC void milli_delay(int milli_sec);

/* keyboard.c */
PUBLIC void init_keyboard();
PUBLIC void keyboard_read(TTY* p_tty);

/* tty.c */
PUBLIC void task_tty();
PUBLIC void in_process(TTY* p_tty, u32 key);

/* systask.c */
PUBLIC void task_sys();

/* console.c */
PUBLIC void out_char(CONSOLE* p_con, char ch);
PUBLIC void scroll_screen(CONSOLE* p_con, int direction);
PUBLIC void select_console(int nr_console);
PUBLIC void init_screen(TTY* p_tty);
PUBLIC int  is_current_console(CONSOLE* p_con);

/* printf.c */
PUBLIC  int     printf(const char *fmt, ...);
#define printl  printf

/* vsprintf.c */
PUBLIC  int     vsprintf(char *buf, const char *fmt, var_list args);
PUBLIC int sprintf(char* buf, const char* fmt, ...);

/* proc.c */
PUBLIC  void    schedule();
PUBLIC  void*   va2la(int pid, void* va);
PUBLIC  int     ldt_seg_linear(PROCESS* p, int idx);
PUBLIC  void    reset_msg(MESSAGE* m);
PUBLIC  void    dump_msg(const char* title, MESSAGE* m);
PUBLIC  void    dump_proc(PROCESS* p);
PUBLIC  int     send_recv(int function, int src_dest, MESSAGE* m);

/* lib/misc.c */
PUBLIC void spin(char * func_name);

/* 以下是系统调用相关 */

/* 系统调用响应函数 - 系统级 */
/* proc.c */
PUBLIC int sys_sendrec(int function, int src_dest, MESSAGE* m, PROCESS* p);
PUBLIC int sys_printx(int _unsed1, int _unsed2, char* s, PROCESS* p);

/* syscall.asm */
PUBLIC  void    sys_call();             /* int_handler */

/* 系统调用 - 用户级 */
PUBLIC  int sendrec(int function, int src_dest, MESSAGE* p_msg);
PUBLIC  int printx(char* str);


