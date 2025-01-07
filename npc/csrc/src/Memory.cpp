#include <cstdint>
#include <memory.h>
Memory::Memory(Args args){
#ifdef CONFIG_YSYXSOC
  areas.emplace_back("flash", 0x30000000, 0x10000000, args.image);
#else 
  areas.emplace_back("sram", 0x80000000, 0x10000000, args.image);
#endif
}

uint32_t Memory::read(uint32_t raddr){
  for (auto&area: areas) {
    if (area.in_mem(raddr)) return area.read<uint32_t>(raddr);
  }
  throw std::runtime_error("No Area\n");
}

void Memory::write(uint32_t waddr, uint32_t wdata, char wmask){
  for (auto&area: areas) {
    if (area.in_mem(waddr)) {
      uint32_t addr = waddr & ~0x3u;
      uint8_t* data = (uint8_t*)&wdata;
      for(int i = 0; i<4; i++){
        if(((1<<i)&wmask) != 0)
          area.write<uint8_t>(waddr + i, data[i]);
      }
      return ;
    }
  }
  throw std::runtime_error("No Area\n");
}

const Area* Memory::find_area_by_name(const std::string& name){
  for (auto& area : areas) {
    if (area.name == name) return &area;
  }
  throw std::runtime_error("No Area\n");
  return nullptr;
}

const Area* Memory::find_area_has_image(){
  for (auto& area : areas) {
    if (area.has_image) return &area;
  }
  throw std::runtime_error("No Area\n");
  return nullptr;
}
