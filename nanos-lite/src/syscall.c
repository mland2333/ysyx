#include <common.h>
#include "syscall.h"
#include "am.h"

int sys_write(Context*c){
  char* buf = (char*)c->GPR3;
  size_t len = c->GPR4;
  for (int i = 0; i < len; i ++) {
    putch(*(buf+i));
  }
  return len;
}

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  int ret = 0;
  switch (a[0]) {
    case SYS_exit: halt(c->GPR2); break;
    case SYS_yield: yield(); break;
    case SYS_write: ret = sys_write(c); break;
    case SYS_brk: break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
  c->GPRx = ret;
}
