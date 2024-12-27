#include "simulator.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sdb.h>
#include <debug/log.h>
#include <debug/disasm.h>
#include <device/device.h>
#include <utils.h>

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

Sdb::Sdb(Args& args, Simulator* sim, Memory* mem) : 
  is_batch(args.is_batch), is_itrace(args.is_itrace), is_ftrace(args.is_ftrace), 
  is_mtrace(args.is_mtrace), is_diff(args.is_diff), is_vga(args.is_vga), 
  sim_(sim), mem_(mem){
  init();
  if (is_itrace) itrace = new Itrace;
  if (is_ftrace) ftrace = new Ftrace(args.image);
  if (is_diff) {
    Area* area = mem_->find_area_has_image();
    diff = new Diff(area, &sim_->cpu);
    diff->init_difftest(diff_file, 1234);
  }
  if (is_vga) init_vga();
  rtc_begin = Utils::get_time();
}

SIM_STATE Sdb::exec_once(){
  clk_nums++;
  SIM_STATE state = sim_->exec_once();
  if (is_time_to_trace){
    if (is_itrace && is_time_to_trace) itrace->trace(sim_->cpu.pc, sim_->get_inst());
    if (is_ftrace) ftrace->trace(pc_, sim_->get_upc(), sim_->is_jump());
    is_time_to_trace = false;
  }
  if (is_diff && is_time_to_diff){
    is_time_to_diff = false;
    if (!diff->difftest_step()) state = SIM_STATE::DIFF_FAILURE;
  } 
  if (is_vga) if (device_update() == -1) state = SIM_STATE::QUIT;
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

uint64_t Sdb::get_rtc(){
  return Utils::get_time() - rtc_begin;
}
void Sdb::statistic(){
  Log("host time spent = %lu us", timer);
  Log("total host clk = %lu", clk_nums);
  Log("total host instructions = %lu", inst_nums);
  if (is_diff) Log("total diff instructions = %lu", diff->diff_nums);
}

int Sdb::run(){
  char args[32];
  char *cmd;
  char *strend;
  std::string line;
  SIM_STATE result;
  if (is_batch) {
    uint64_t now = Utils::get_time();
    result = cmd_c(this, nullptr);
    timer += Utils::get_time() - now;
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
      uint64_t now = Utils::get_time();
      result = sdb_map_[cmd](this, sdb_args);
      timer += Utils::get_time() - now;
      if (result != SIM_STATE::NORMAL) {
        break;
      }
      std::cout << "(npc) ";
    }
  }
  switch (result) {
    case SIM_STATE::QUIT :
      if (sim_->cpu.gpr[10] == 0)
        Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN), sim_->cpu.pc);
      else 
        Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED), sim_->cpu.pc);
      break;
    default: 
      Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED), sim_->cpu.pc);
      break;
  }
  
  return 0;
}

Sdb::~Sdb(){
  statistic();
  if (is_ftrace) delete ftrace;
  if (is_itrace) delete itrace;
  if (is_diff) delete diff;
}
