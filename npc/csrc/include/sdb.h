#pragma once

#include <cstdint>
#include <functional>
#include <unordered_map>
#include <iostream>
#include <simulator.h>
#include <memory.hpp>
#include <args.h>
#include <cpu.h>
enum class NPC_STATE{
  RUNNING,
  STOP,
  ABORT,
  QUIT
};
class Sdb{
  std::unordered_map<std::string, std::function<SIM_STATE(Simulator*, char*)>> sdb_map_;
  bool is_batch = false;
  NPC_STATE state = NPC_STATE::RUNNING;
  uint64_t timer = 0;
  void statistic();
  uint64_t get_time();
public:
  Sdb(Args& args) : is_batch(args.is_batch){
    init();
  }
  void init();
  void welcome();
  void add_command(const char* command, std::function<SIM_STATE(Simulator*, char*)> func){
    sdb_map_[command] = func;
  }
  int run(Simulator* sim_);
};
