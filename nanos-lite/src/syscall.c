#include <common.h>
#include <stdint.h>
#include "syscall.h"
#include "am.h"
static const char*syscall_name[] = {
  "SYS_exit",
  "SYS_yield",
  "SYS_open",
  "SYS_read",
  "SYS_write",
  "SYS_kill",
  "SYS_getpid",
  "SYS_close",
  "SYS_lseek",
  "SYS_brk",
  "SYS_fstat",
  "SYS_time",
  "SYS_signal",
  "SYS_execve",
  "SYS_fork",
  "SYS_link",
  "SYS_unlink",
  "SYS_wait",
  "SYS_times",
  "SYS_gettimeofday"
};

void sys_write(Context *c){
  char* buf = (char*)c->gpr[11];
  intptr_t len = (intptr_t)c->gpr[12];
  for (int i = 0; i < len; i++) {
    putch(*(buf+i));
  }
}
void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  printf("%s\n", syscall_name[a[0]]);
  switch (a[0]) {
    case 0: halt(c->GPR1); break;
    case 1: yield();break;
    case 4: 
      if(c->gpr[10] == 1 || c->gpr[10] == 2) {
        sys_write(c);
      }
    break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
   c->GPRx = 0;
}


