#include <memory.hpp>
#include <sys/types.h>


Memory::Memory(){
  base_ = 0x80000000;
  size_ = 0x1000000;
  mem_ = new char[size_];
  init();
}
Memory::Memory(uint32_t base, uint32_t size) : base_(base), size_(size){
  mem_ = new char[size_];
  init();
}
Memory::Memory(uint32_t base, uint32_t size, std::string& filename) : base_(base), size_(size){
  mem_ = new char[size_];
}

Memory::~Memory(){
  delete[] mem_;
}
