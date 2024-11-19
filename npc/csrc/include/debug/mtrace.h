#pragma once

#include <cstdint>
class Mtrace{
  uint32_t waddr, raddr;
  uint32_t wdata, rdata;
  bool read_happened = false, write_happend = false;
public:
  void trace();
};
