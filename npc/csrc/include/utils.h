#pragma once

#include <cstdint>
#include <chrono>
namespace Utils{

inline uint64_t get_time(){
  auto now = std::chrono::system_clock::now();
  return (std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch())).count();
}

}
