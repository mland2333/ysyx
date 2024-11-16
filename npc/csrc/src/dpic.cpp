#include <sdb.h>
extern Sdb* sdb;

extern "C" int inst_fetch(int pc){
  return sdb->inst_fetch(pc);
}
extern "C" void quit(){
  sdb->quit();
}
