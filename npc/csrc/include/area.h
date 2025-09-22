#pragma once

#include <cassert>
#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <utils.h>
class Area {
public:
  Area(uint32_t base, uint32_t size) : base(base), size(size) {}
  bool in_mem(uint32_t addr) {
    return (addr >= base) && (addr < (base + size));
  }
  virtual ~Area() = default;
  virtual int read(uint32_t addr) = 0;
  virtual void write(uint32_t addr, uint32_t data, uint8_t mask) {
    throw std::runtime_error(
        "Write operation not supported for this memory region");
  }
  Area(const Area &) = delete;
  Area &operator=(const Area &) = delete;
  const uint32_t base, size;
  bool device = true;
};

class RamArea : public Area {
private:
  char *mem = nullptr;

public:
  RamArea(uint32_t base, uint32_t size, const char *img) : Area(base, size) {
    mem = new char[size];
    Utils::load_img(mem, img);
    device = false;
  }
  int read(uint32_t addr) override {
    addr = addr & ~0x3u;
    uint64_t paddr = reinterpret_cast<uint64_t>(mem + addr - base);
    uint32_t *raddr = reinterpret_cast<uint32_t *>(paddr);
    return *raddr;
  }
  void write(uint32_t addr, uint32_t data, uint8_t mask) override {
    // addr = addr & ~0x3u;
    uint64_t paddr = reinterpret_cast<uint64_t>(mem + addr - base);
    uint8_t *waddr = reinterpret_cast<uint8_t *>(paddr);
    uint8_t *wdata = reinterpret_cast<uint8_t *>(&data);
    for (int i = 0; i < 4; i++) {
      if (((1 << i) & mask) != 0)
        *(waddr + i) = wdata[i];
    }
  }
  ~RamArea() override {
    if (mem != nullptr)
      delete[] mem;
  }
};

class UartArea : public Area {
public:
  UartArea(uint32_t base, uint32_t size) : Area(base, size) {}
  int read(uint32_t addr) override { return 0; }
  void write(uint32_t addr, uint32_t data, uint8_t mask) override {
    std::cout << (char)data << std::flush;
  }
};

class ClintArea : public Area {
private:
  uint64_t begin_time;
  uint64_t rtc_time;

public:
  ClintArea(uint32_t base, uint32_t size) : Area(base, size) {
    begin_time = Utils::get_time();
    rtc_time = 0;
  }
  int read(uint32_t addr) override {
    if (addr == base + 4) {
      rtc_time = Utils::get_time() - begin_time;
      return (int)(rtc_time >> 32);
    }
    return (int)rtc_time;
  }
};
