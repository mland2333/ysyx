#pragma once

#include <args.h>
#include <area.hpp>
#include <cstdint>
#include <vector>

class Memory{
public:
  std::vector<Area> areas;

  Memory(Args);
  uint32_t read(uint32_t raddr);
  void write(uint32_t waddr, uint32_t wdata, char wmask);
  const Area* find_area_by_name(const std::string& name);
  const Area* find_area_has_image();
};
