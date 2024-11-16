#include "simulator.h"
#include <cstdio>
#include <cstring>
#include <sdb.h>
#include <debug/log.h>
#include <chrono>
#include <debug/disasm.h>
SIM_STATE cmd_c(Sdb* sdb, char* args){
  SIM_STATE sim_state;
  while (true) {
    sim_state = sdb->exec_once();
    if(sim_state == SIM_STATE::NORMAL) continue;
    else return sim_state;
  }
}
SIM_STATE cmd_si(Sdb* sdb, char* args){
  SIM_STATE sim_state;
  int n = args == nullptr ? 1 : atoi(strtok(args, " "));
  return sdb->exec(n);
}
SIM_STATE cmd_q(Sdb* sdb, char* args){
  return SIM_STATE::QUIT;
}
SIM_STATE cmd_x(Sdb* sdb, char* args){
  char* arg1 = strtok(args, " ");
  char* arg2 = args + strlen(arg1) + 1;
  int n = atoi(arg1);
  uint32_t addr;
  sscanf(arg2, "%x", &addr);
  for(int i = 0; i<n; i++){
    printf("(0x%x) = 0x%x\n", addr+i*4, sdb->mem_read(addr+i*4));
  }
  return SIM_STATE::NORMAL;
}
SIM_STATE cmd_p(Sdb* sdb, char* args){
  return SIM_STATE::NORMAL;
}
SIM_STATE cmd_info(Sdb* sdb, char* args){
  sdb->cpu_display();
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
static char inst_buf[128];
static char logstr[128];
SIM_STATE Sdb::exec_once(){
  inst_nums++;
  SIM_STATE state = sim_->exec_once();
  if (is_itrace){
    disassemble(inst_buf, 128, (uint64_t)pc_, (uint8_t *)(&inst_), 4);
    sprintf(logstr, "0x%x\t0x%08x\t%s\t", pc_, inst_, inst_buf);
    printf(logstr);
    itrace.insert_buffer(logstr);
  }
  return state;
}

SIM_STATE Sdb::exec(int n){
  for (int i = 0; i < n; i++) {
    SIM_STATE sim_state = exec_once();
    if(sim_state == SIM_STATE::NORMAL) continue;
    else return sim_state;
  }
  return SIM_STATE::NORMAL;
}

void Sdb::welcome(){
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to npc\n");
  printf("For help, type \"help\"\n");
}

uint64_t Sdb::get_time(){
  auto now = std::chrono::system_clock::now();
  return (std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch())).count();
}
void Sdb::statistic(){
  Log("host time spent = %lu us", timer);
  Log("total host instructions = %lu", inst_nums);
}
int Sdb::run(){
  char args[32];
  char *cmd;
  char *strend;
  std::string line;
  SIM_STATE result;
  if (is_batch) {
    result = cmd_c(this, nullptr);
  }
  else {
    std::cout << "(npc) ";
    while (getline(std::cin, line)) {
      strcpy(args, line.c_str());
      strend = args + strlen(args);
      cmd = strtok(args, " ");
      char *sdb_args = cmd + strlen(cmd) + 1;
      if (sdb_args >= strend)
        sdb_args = nullptr;
      uint64_t now = get_time();
      result = sdb_map_[cmd](this, sdb_args);
      timer += get_time() - now;
      switch (result) {
        case SIM_STATE::NORMAL : break;
        case SIM_STATE::QUIT :
          Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN), sim_->cpu.pc);
          statistic();
          return 0;
        default: 
          Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED), sim_->cpu.pc);
          statistic();
          return 0;
      }
      std::cout << "(npc) ";
    }
  }
  itrace.print_buffer();
  return 0;
}
