#pragma once

#include <area.hpp>
#include <cstdint>
#include <vector>

class Memory{
public:
  std::vector<Area*> areas_;

  Memory(std::vector<Area*> && areas_);
  uint32_t read(uint32_t raddr);
  void write(uint32_t waddr, uint32_t wdata, char wmask);
  Area* find_area_by_name(const std::string name);
};
