#pragma once

#include <cassert>
#include <cstdint>
#include <ios>
#include <iostream>

class Memory {
  char* mem_;
  uint32_t base_;
  uint32_t size_;
  uint64_t translate(uint32_t vaddr) const{
    if(!(vaddr >= base_ && vaddr < base_ + size_)){
      std::cout << "vaddr = " << std::hex << vaddr << '\n';
      assert(0);
    }
    return reinterpret_cast<uint64_t>(mem_ + vaddr - base_);
  }
  void init(){
    write<uint32_t>(base_, 0x00100513);
    write<uint32_t>(base_ + 4, 0x00150513);
    write<uint32_t>(base_ + 8, 0x00150513);
    write<uint32_t>(base_ + 12, 0x00150513);
    write<uint32_t>(base_ + 16, 0x00150513);
    write<uint32_t>(base_ + 20, 0x100073);
  }
public:
  Memory();
  Memory(uint32_t base, uint32_t size);
  Memory(uint32_t base, uint32_t size, const char* image);
  long load_img(const char* image);
  template<typename T>
  T read(uint32_t vaddr) const;
  template<typename T>
  void write(uint32_t vaddr, T value) const;
  ~Memory();
};

template<typename T>
T Memory::read(uint32_t vaddr) const{
  static_assert(std::is_integral<T>::value && sizeof(T) == 1 || sizeof(T) == 2 || sizeof(T) == 4, "只支持uint8 uint16 uint32");
  uint64_t paddr = translate(vaddr);
  return *reinterpret_cast<T*>(paddr);
}

template<typename T>
void Memory::write(uint32_t vaddr, T value) const{
  static_assert(std::is_integral<T>::value && sizeof(T) == 1 || sizeof(T) == 2 || sizeof(T) == 4, "只支持uint8 uint16 uint32");
  uint64_t paddr = translate(vaddr);
  *reinterpret_cast<T*>(paddr) = value;
}
