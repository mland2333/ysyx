#include "area.h"
#include <cstdint>
#include <cstdio>
#include <memory.h>
Memory::Memory(Args args) {
  areas.emplace_back(
      std::make_unique<RamArea>(0x80000000, 0x10000000, args.image));
  areas.emplace_back(std::make_unique<UartArea>(0xa00003f8, 0x4));
  areas.emplace_back(std::make_unique<ClintArea>(0xa0000048, 0x8));
}

uint32_t Memory::read(uint32_t raddr) {
  for (auto &area : areas) {
    if (area->in_mem(raddr))
      return area->read(raddr);
  }
  throw std::runtime_error("No Area\n");
  return 0;
}

void Memory::write(uint32_t waddr, uint32_t wdata, char wmask) {
  for (auto &area : areas) {
    if (area->in_mem(waddr)) {
      area->write(waddr, wdata, wmask);
      return;
    }
  }
  throw std::runtime_error("No Area\n");
}

bool Memory::in_devide_area(uint32_t addr) {
  for (auto &area : areas) {
    if (area->in_mem(addr))
      return area->device;
  }
  return false;
}
