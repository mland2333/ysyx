#include <common.h>
#include <stdio.h>
#include "syscall.h"
#include "am.h"
#include <fs.h>
const char* syscall_name[] = {
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
int sys_write(Context*c){
  int fd = c->GPR2;
  char* buf = (char*)c->GPR3;
  size_t len = c->GPR4;
  return fs_write(fd, buf, len);
}
int sys_open(Context* c){
  char* file_path = (char*)c->GPR2;
  int flags = c->GPR3;
  int mode = c->GPR4;
  return fs_open(file_path, flags, mode);
}
int sys_read(Context* c){
  int fd = c->GPR2;
  char* buf = (char*)c->GPR3;
  size_t len = c->GPR4;
  return fs_read(fd, buf, len);
}
int sys_close(Context* c){
  int fd = c->GPR2;
  return fs_close(fd);
}

int sys_lseek(Context* c){
  int fd = c->GPR2;
  size_t offset = c->GPR3;
  int whence = c->GPR4;
  if(fd == 0 || fd == 1 || fd == 2) return 0;
  return fs_lseek(fd, offset, whence);
}

int sys_gettimeofday(Context* c){
  struct timeval* st = (struct timeval*) c->GPR2;
  intptr_t now_time = io_read(AM_TIMER_UPTIME).us;
  st->tv_sec = now_time / 1000000;
  st->tv_usec = now_time;
  return 0;
}


void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  if (true) {
    printf("%s ", syscall_name[a[0]]);
    if (a[0] == SYS_open)
      printf("%s", (char*)c->GPR2);
    else if (a[0] == SYS_read || a[0] == SYS_write)
      printf("%s, len = %d", get_file_name_by_fd(c->GPR2), c->GPR4);
    else if(a[0] == SYS_lseek)
      printf("%s, offset = %d", get_file_name_by_fd(c->GPR2), c->GPR3);
    else if(a[0] == SYS_close)
      printf("%s", get_file_name_by_fd(c->GPR2));
    else if(a[0] == SYS_brk)
      printf("increment = 0x%x", c->GPR2);
    printf("\n");
  }
  int ret = 0;
  switch (a[0]) {
    case SYS_exit: halt(c->GPR2); break;
    case SYS_yield: yield(); break;
    case SYS_open: ret = sys_open(c); break;
    case SYS_read: ret = sys_read(c); break;
    case SYS_write: ret = sys_write(c); break;
    case SYS_close: ret = sys_close(c); break;
    case SYS_lseek: ret = sys_lseek(c); break;
    case SYS_brk: break;
    case SYS_gettimeofday: ret = sys_gettimeofday(c); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
  c->GPRx = ret;
}
