#include <sdb.h>
extern Sdb *sdb;

extern "C" void quit() { sdb->quit(); }

extern "C" int pmem_read(int raddr) {
  return sdb->mem_read(raddr);
}
extern "C" void pmem_write(int waddr, int wdata, char wmask) {
    sdb->mem_write(waddr, wdata, wmask & 0x0f);
}
extern "C" int fetch_inst(int pc) { return sdb->fetch_inst(pc); }
