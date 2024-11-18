#include <sdb.h>
extern Sdb* sdb;

extern "C" int inst_fetch(int pc){
  return sdb->inst_fetch(pc);
}
extern "C" void quit(){
  sdb->quit();
}

extern "C" int pmem_read(int raddr){
  return sdb->mem_read(raddr & ~0x3u);
}

extern "C" void pmem_write(int waddr, int wdata, char wmask){
  sdb->mem_write(waddr & ~0x3u, wdata, wmask & 0x0f);
}
