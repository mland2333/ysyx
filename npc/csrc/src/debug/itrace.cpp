#include <debug/itrace.h>
#include <cstring>
#include <cstdio>
#include <debug/disasm.h>
Itrace::Itrace(){
  extern void init_disasm(const char*);
  init_disasm("riscv32-linux-pc-gnu");
}
void Itrace::insert_buffer(char* logstr){
  memcpy(ring_buffer[buffer_index%MAX_RING_BUFFER], logstr, 128);
  ++buffer_index;
}

void Itrace::print_buffer(){
  if(buffer_index <=  MAX_RING_BUFFER)
  {
    for(int i = 0; i<buffer_index; i++)
      printf("%s\n", ring_buffer[i]);
  }
  else {
    for(int i = 0; i < MAX_RING_BUFFER; i++)
      printf("%s\n", ring_buffer[(buffer_index+i)%MAX_RING_BUFFER]);
  }
}
