#pragma once

#include <cassert>
#include <cstdint>
#include <ios>
#include <iostream>
#include <stdexcept>
#include <utils.h>
class Area {
public:
  const uint32_t base_;
  const uint32_t size_;
  std::string name_;
  long img_size;
  uint64_t translate(uint32_t vaddr) const{
    if(!(vaddr >= base_ && vaddr < base_ + size_)){
      std::cout << "vaddr = " << std::hex << vaddr << '\n';
      throw std::runtime_error("Area error\n");
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
  char* mem_;
  Area(std::string&& name, uint32_t base, uint32_t size);
  Area(std::string&& name, uint32_t base, uint32_t size, const char* image);
  Area(const Area&) = delete;            
  Area& operator=(const Area&) = delete; 
  Area(Area&& other) noexcept;           
  Area& operator=(Area&& other) noexcept;

  bool in_mem(uint32_t vaddr){
    return vaddr >= base_ && vaddr < base_ + size_;
  }
  template<typename T>
  T read(uint32_t vaddr) const;
  template<typename T>
  void write(uint32_t vaddr, T value) const;
  ~Area();
};

inline Area::Area(std::string&& name, uint32_t base, uint32_t size) : name_(std::move(name)), base_(base), size_(size){
  mem_ = new char[size_];
  img_size = 4096;
  init();
}
inline Area::Area(std::string&& name, uint32_t base, uint32_t size, const char* image) : name_(std::move(name)), base_(base), size_(size){
  mem_ = new char[size_];
  img_size = Utils::load_img(mem_, image);
}

inline Area::~Area(){
  delete [] mem_;
}
template<typename T>
T Area::read(uint32_t vaddr) const{
  static_assert(std::is_integral<T>::value && sizeof(T) == 1 || sizeof(T) == 2 || sizeof(T) == 4, "只支持uint8 uint16 uint32");
  uint64_t paddr = translate(vaddr);
  return *reinterpret_cast<T*>(paddr);
}

template<typename T>
void Area::write(uint32_t vaddr, T value) const{
  static_assert(std::is_integral<T>::value && sizeof(T) == 1 || sizeof(T) == 2 || sizeof(T) == 4, "只支持uint8 uint16 uint32");
  uint64_t paddr = translate(vaddr);
  *reinterpret_cast<T*>(paddr) = value;
}

