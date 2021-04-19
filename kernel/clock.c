#include "type.h"
#include "const.h"
#include "protect.h"
#include "tty.h"
#include "console.h"
#include "proc.h"
#include "proto.h"
#include "string.h"
#include "global.h"


PUBLIC  void clock_handler(int irq)
{
    // disp_str("#");
    ticks++;
    p_proc_ready->ticks--;

    if (k_reenter != 0)
    {
        // disp_str("!");
        return;
    }

    //一个进程ticks不为0，即还未执行完成，是不会调度到下一个进程的
    //变成从高到低优先级的进程轮转执行
    if(p_proc_ready->ticks > 0)
    {
        return;
    }
    
    schedule();

    // p_proc_ready++;
    // //相当于数组++
    // if (p_proc_ready >= proc_table + NR_TASKS)
    // {
    //     p_proc_ready = proc_table;
    // }
    // //AB循环交替执行
}

PUBLIC  void milli_delay(int milli_sec)
{
    int t = get_ticks();

    while (((get_ticks() - t) * 1000 / HZ) < milli_sec)
    {
        /* code */
    }
    
}

/*======================================================================*
                           init_clock
 *======================================================================*/
PUBLIC void init_clock()
{
        /* 初始化 8253 PIT */
        out_byte(TIMER_MODE, RATE_GENERATOR);
        out_byte(TIMER0, (u8) (TIMER_FREQ/HZ) );
        out_byte(TIMER0, (u8) ((TIMER_FREQ/HZ) >> 8));

        put_irq_handler(CLOCK_IRQ, clock_handler);    /* 设定时钟中断处理程序 */
        enable_irq(CLOCK_IRQ);                        /* 让8259A可以接收时钟中断 */
}