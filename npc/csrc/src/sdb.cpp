#include "simulator.h"
#include <cstdio>
#include <cstring>
#include <sdb.h>

SIM_STATE cmd_c(Simulator* sim_, char* args){
  SIM_STATE sim_state;
  while (true) {
    sim_state = sim_->exec_once();
    if(sim_state == SIM_STATE::NORMAL) continue;
    else return sim_state;
  }
}
SIM_STATE cmd_si(Simulator* sim_, char* args){
  SIM_STATE sim_state;
  int n = args == nullptr ? 1 : atoi(strtok(args, " "));
  for (int i = 0; i < n; i++) {
    sim_state = sim_->exec_once();
    if(sim_state == SIM_STATE::NORMAL) continue;
    else return sim_state;
  }
  return SIM_STATE::NORMAL;
}
SIM_STATE cmd_q(Simulator* sim_, char* args){
  return SIM_STATE::QUIT;
}
SIM_STATE cmd_x(Simulator* sim_, char* args){
  char* arg1 = strtok(args, " ");
  char* arg2 = args + strlen(arg1) + 1;
  int n = atoi(arg1);
  uint32_t addr;
  sscanf(arg2, "%x", &addr);
  extern Memory mem;
  for(int i = 0; i<n; i++){
    printf("(0x%x) = 0x%x\n", addr+i*4, mem.read<uint32_t>(addr+i*4));
  }
  return SIM_STATE::NORMAL;
}
SIM_STATE cmd_p(Simulator* sim_, char* args){
  return SIM_STATE::NORMAL;
}
SIM_STATE cmd_info(Simulator* sim_, char* args){
  sim_->cpu.display();
  return SIM_STATE::NORMAL;
}
void Sdb::init(){
  sdb_map_["c"] = cmd_c;
  sdb_map_["si"] = cmd_si;
  sdb_map_["q"] = cmd_q;
  sdb_map_["x"] = cmd_x;
  sdb_map_["p"] = cmd_p;
  sdb_map_["info"] = cmd_info;
  /* sdb_map_["c"] = [this](char*args) -> NPC_STATE { */
  /*   while (true) { */
  /*     if (sim_.exec_once() != SIM_STATE::NORMAL) { */
  /*       return NPC_STATE::ABORT; */
  /*     } */
  /*   } */
  /*   return NPC_STATE::QUIT; */
  /* }; */
}

int Sdb::run(Simulator* sim_){
  char args[32];
  char *cmd;
  char *strend;
  std::string line;
  SIM_STATE result;
  if (is_batch) {
    result = cmd_c(sim_, nullptr);
    if (result == SIM_STATE::QUIT)
      return 0;
  }
  else {
    std::cout << "<< ";
    while (getline(std::cin, line)) {
      strcpy(args, line.c_str());
      strend = args + strlen(args);
      cmd = strtok(args, " ");
      char *sdb_args = cmd + strlen(cmd) + 1;
      if (sdb_args >= strend)
        sdb_args = nullptr;
      result = sdb_map_[cmd](sim_, sdb_args);
      if (result == SIM_STATE::QUIT)
        return 0;
      std::cout << "<< ";
    }
  }
  return 0;
}
