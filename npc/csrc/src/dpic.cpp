#include <sdb.h>
extern Sdb* sdb;

extern "C" int inst_fetch(int pc){
  return sdb->mem_read(pc);
}
extern "C" void quit(){
  sdb->quit();
}
