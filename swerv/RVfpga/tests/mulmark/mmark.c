#if defined(D_NEXYS_A7)
   #include <bsp_printf.h>
   #include <bsp_mem_map.h>
   #include <bsp_version.h>
#else
   PRE_COMPILED_MSG("no platform was defined")
#endif
#include <psp_api.h>

#define GPIO_SWs    0x80001400
#define GPIO_LEDs   0x80001404
#define GPIO_INOUT  0x80001408

#define READ_GPIO(dir) (*(volatile unsigned *)dir)
#define WRITE_GPIO(dir, value) { (*(volatile unsigned *)dir) = (value); }


int cyc_beg, cyc_end;
int instr_beg, instr_end;
int LdSt_beg, LdSt_end;
int Inst_beg, Inst_end;
static clock_t start_time_val, stop_time_val;

void mulmark(void);

void start_time(void) {
    uint32_t mcyclel;
    asm volatile ("csrr %0,mcycle"  : "=r" (mcyclel) );
    start_time_val = mcyclel;
}

clock_t get_time(void) {
    clock_t elapsed=(clock_t)(stop_time_val - start_time_val);
    return elapsed;
}

void stop_time(void) {
    uint32_t mcyclel;
    asm volatile ("csrr %0,mcycle"  : "=r" (mcyclel) );
    stop_time_val = mcyclel;
}


int main(void)
{
   /* Initialize Uart */
   uartInit();

   pspEnableAllPerformanceMonitor(1);

   pspPerformanceCounterSet(D_PSP_COUNTER0, E_CYCLES_CLOCKS_ACTIVE);
   pspPerformanceCounterSet(D_PSP_COUNTER1, E_INSTR_COMMITTED_ALL);
   pspPerformanceCounterSet(D_PSP_COUNTER2, E_D_BUD_TRANSACTIONS_LD_ST);
   pspPerformanceCounterSet(D_PSP_COUNTER3, E_I_BUS_TRANSACTIONS_INSTR);

   /* Modify core features as desired */
   __asm("li t2, 0x000");
   __asm("csrrs t1, 0x7F9, t2");

   /* Invert Switch to execute CoreMark*/ 
   int switches_value, switches_init;
   WRITE_GPIO(GPIO_INOUT, 0xFFFF);
   switches_init = (READ_GPIO(GPIO_SWs) >> 16);
   switches_value = switches_init;
   while (switches_value==switches_init) { 
        switches_value = (READ_GPIO(GPIO_SWs) >> 16);
        printfNexys("Invert any Switch to execute CoreMark");
   }

   mulmark();

   printfNexys("Cycles = %d", cyc_end-cyc_beg);
   printfNexys("Instructions = %d", instr_end-instr_beg);
   printfNexys("Data Bus Transactions = %d", LdSt_end-LdSt_beg);
   printfNexys("Inst Bus Transactions = %d", Inst_end-Inst_beg);

   while(1);
}

/* perform actual benchmark */
void mulmark() {
    clock_t total_time;
    int x = 1;
    int y = 1;
    int z;
    int i = 0;

    start_time();

    __asm("__perf_start:");

    cyc_beg = pspPerformanceCounterGet(D_PSP_COUNTER0);
    instr_beg = pspPerformanceCounterGet(D_PSP_COUNTER1);
    LdSt_beg = pspPerformanceCounterGet(D_PSP_COUNTER2);
    Inst_beg = pspPerformanceCounterGet(D_PSP_COUNTER3);
    
    for(i; i < 1000; i++) { // TODO: switch to asm
        y *= x;
        z *= y;
    }

    cyc_end = pspPerformanceCounterGet(D_PSP_COUNTER0);
    instr_end = pspPerformanceCounterGet(D_PSP_COUNTER1);
    LdSt_end = pspPerformanceCounterGet(D_PSP_COUNTER2);
    Inst_end = pspPerformanceCounterGet(D_PSP_COUNTER3);
    
    __asm("__perf_end:");

    stop_time();
    total_time=get_time();
    
    printfNexys("z = %d", z);
}