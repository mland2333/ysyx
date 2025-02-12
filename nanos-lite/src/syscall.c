#include <common.h>
#include <stdint.h>
#include "syscall.h"
#include "am.h"
/* static const char*syscall_name[] = { */
/*   "SYS_exit", */
/*   "SYS_yield", */
/*   "SYS_open", */
/*   "SYS_read", */
/*   "SYS_write", */
/*   "SYS_kill", */
/*   "SYS_getpid", */
/*   "SYS_close", */
/*   "SYS_lseek", */
/*   "SYS_brk", */
/*   "SYS_fstat", */
/*   "SYS_time", */
/*   "SYS_signal", */
/*   "SYS_execve", */
/*   "SYS_fork", */
/*   "SYS_link", */
/*   "SYS_unlink", */
/*   "SYS_wait", */
/*   "SYS_times", */
/*   "SYS_gettimeofday" */
/* }; */

int sys_write(Context *c){
  char* buf = (char*)c->GPR3;
  intptr_t len = (intptr_t)c->GPR4;
  for (int i = 0; i < len; i++) {
    putch(*(buf+i));
  }
  return len;
}

int sys_brk(Context *c){
  return 0;
}
void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  int ret = 0;
  /* printf("%s\n", syscall_name[a[0]]); */
  switch (a[0]) {
    case SYS_exit: halt(c->GPR1);break;
    case SYS_yield: yield();break;
    case SYS_write: 
      if(c->GPR2 == 1 || c->GPR2 == 2) {
        ret = sys_write(c);
      }
    break;
    case SYS_brk:
      sys_brk(c);
    break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
   c->GPRx = ret;
}


