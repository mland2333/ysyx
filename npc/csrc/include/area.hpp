#pragma once

#include <cassert>
#include <cstdint>
#include <ios>
#include <iostream>
#include <stdexcept>
#include <utils.h>
class Area {
public:
  const uint32_t base;
  const uint32_t size;
  std::string name;
  long img_size;
  bool has_image = false;
  uint64_t translate(uint32_t vaddr) const{
    if(!(vaddr >= base && vaddr < base + size)){
      std::cout << "vaddr = " << std::hex << vaddr << '\n';
      throw std::runtime_error("Area error\n");
    }
    return reinterpret_cast<uint64_t>(mem + vaddr - base);
  }
  void init(){
    write<uint32_t>(base, 0x00100513);
    write<uint32_t>(base + 4, 0x00150513);
    write<uint32_t>(base + 8, 0x00150513);
    write<uint32_t>(base + 12, 0x00150513);
    write<uint32_t>(base + 16, 0x00150513);
    write<uint32_t>(base + 20, 0x100073);
  }
  char* mem;
  Area(std::string&& name, uint32_t base, uint32_t size);
  Area(std::string&& name, uint32_t base, uint32_t size, const char* image);
  Area (Area&& that) noexcept : base(that.base), size(that.base), name(std::move(that.name)),
  img_size(that.img_size), has_image(that.has_image), mem(that.mem){
    that.mem = nullptr;
  };

  Area(const Area&) = delete;
  Area& operator=(const Area&) = delete; 

  bool in_mem(uint32_t vaddr){
    return vaddr >= base && vaddr < base + size;
  }
  template<typename T>
  T read(uint32_t vaddr) const;
  template<typename T>
  void write(uint32_t vaddr, T value) const;
  ~Area();
};

inline Area::Area(std::string&& name_, uint32_t base_, uint32_t size_) : name(std::move(name_)), base(base_), size(size_){
  mem = new char[size];
  img_size = 4096;
  init();
}
inline Area::Area(std::string&& name_, uint32_t base_, uint32_t size_, const char* image) : name(std::move(name_)), base(base_), size(size_){
  mem = new char[size];
  img_size = Utils::load_img(mem, image);
  has_image = true;
}

inline Area::~Area(){
  delete [] mem;
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

