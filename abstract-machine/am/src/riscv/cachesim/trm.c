#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <ysyxsoc.h>
extern char _heap_start[];
extern char _stack_top[];
extern char _boot_load_start[];
extern char _boot_start[];
extern char _boot_end[];

extern char _text_load_start[];
extern char _text_start[];
extern char _data_start[];
extern char _data_end[];
extern char _data_load_start[];
extern char _bss_end[];

int main(const char *args);

/* extern char _pmem_start; */
/* #define PMEM_SIZE (128 * 1024 * 1024) */
/* #define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE) */


void load_data(){
  char* src = _data_load_start;
  char* dst = _data_start;
  /* printf("_data_load_start = 0x%x\n", _data_load_start); */
  /* printf("_data_load_end = 0x%x\n", _data_load_end); */
  /* printf("_data_start = 0x%x\n", _data_start); */
  /* printf("_data_end = 0x%x\n", _data_end); */
  while(dst != _data_end){
    *dst = *src;
    src++;
    dst++;
  }
}

Area heap = RANGE(&_heap_start, _stack_top);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  /* while((UartReadReg(LSR) & LSR_TX_IDLE) == 0); */
  UartWriteReg(THR, ch);
}
char getch() {
  if(UartReadReg(LSR) & 0x01){
    // input data is ready.
    char a = UartReadReg(RBR);
    /* putch(a); */
    return a;
  } else {
    return 0xff;
  }
}
void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  __builtin_unreachable();
}

void uart_init(){
  UartWriteReg(3, (1 << 7));
  UartWriteReg(DLL, 0x06);
  UartWriteReg(DLM, 0x00);
  UartWriteReg(LCR, (3 << 0));
}

void _trm_init() {
  /* load_data(); */
  uart_init();
  /* unsigned int mvendorid, marchid; */
  /* asm volatile("csrr %0, mvendorid" : "=r"(mvendorid)); */
  /* asm volatile("csrr %0, marchid" : "=r"(marchid)); */
  /* for(int i = 0; i<4; i++){ */
  /*   putch(*((char*)&mvendorid + 3 - i)); */
  /* } */
  /* putch('_'); */
  /* printf("%d\n", marchid); */
  int ret = main(mainargs);
  halt(ret);
}
