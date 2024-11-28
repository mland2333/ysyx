#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>
extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)
extern char _data_start[];
extern char _data_end[];
extern char _data_load_start[];

void load_data(){
  char* src = _data_load_start;
  char* dst = _data_start;
  //printf("%x, %x\n", (int)_data_end , (int)dst);
  while(dst != _data_end){
    *dst = *src;
    src++;
    dst++;
  }
}

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  while((UartReadReg(LSR) & LSR_TX_IDLE) == 0);
  UartWriteReg(THR, ch);
}

void halt(int code) {
  asm volatile ("ebreak" : :);
  __builtin_unreachable();
}

void uart_init(){
  UartWriteReg(3, (1 << 7));
  UartWriteReg(DLL, 0x06);
  UartWriteReg(DLM, 0x00);
  UartWriteReg(LCR, (3 << 0));
}

void _trm_init() {
  load_data();
  uart_init();
  int ret = main(mainargs);
  halt(ret);
}
