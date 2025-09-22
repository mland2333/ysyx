#pragma once

#include <area.h>
#include <args.h>
#include <cstdint>
#include <memory>
#include <vector>

class Memory {

  std::vector<std::unique_ptr<Area>> areas;

public:
  Memory(Args);
  uint32_t read(uint32_t raddr);
  void write(uint32_t waddr, uint32_t wdata, char wmask);
  bool in_devide_area(uint32_t addr);
};
