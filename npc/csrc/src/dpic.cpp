#include <memory.hpp>
#include <simulator.h>

extern Memory* mem;
extern Simulator* sim;

extern "C" int inst_fetch(int pc){
  return mem->read<uint32_t>(pc);
}
extern "C" void quit(){
  sim->quit();
}
