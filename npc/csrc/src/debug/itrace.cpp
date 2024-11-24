#include <debug/itrace.h>
#include <cstring>
#include <cstdio>
#include <debug/disasm.h>
Itrace::Itrace(){
  init_disasm();
}
void Itrace::insert_buffer(){
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

void Itrace::trace(uint32_t pc, uint32_t inst){
  disassemble(inst_buf, 128, (uint64_t)pc, (uint8_t *)(&inst), 4);
  sprintf(logstr, "0x%x\t0x%08x\t%s\t", pc, inst, inst_buf);
  insert_buffer();
}

Itrace::~Itrace(){
  print_buffer();
}
