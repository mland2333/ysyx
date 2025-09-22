#include "cpu.h"
#include "sim.h"
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <debug/disasm.h>
#include <debug/log.h>
#include <device/device.h>
#include <sched.h>
#include <sdb.h>
#include <sys/wait.h>
#include <unistd.h>
#include <utils.h>

SIM_STATE cmd_c(Sdb *sdb, char *args) { return sdb->exec(-1); }
SIM_STATE cmd_si(Sdb *sdb, char *args) {
  SIM_STATE sim_state;
  int n = args == nullptr ? 1 : atoi(strtok(args, " "));
  return sdb->exec(n);
}
SIM_STATE cmd_q(Sdb *sdb, char *args) { return SIM_STATE::QUIT; }
SIM_STATE cmd_x(Sdb *sdb, char *args) {
  char *arg1 = strtok(args, " ");
  char *arg2 = args + strlen(arg1) + 1;
  int n = atoi(arg1);
  uint32_t addr;
  sscanf(arg2, "%x", &addr);
  for (int i = 0; i < n; i++) {
    printf("(0x%x) = 0x%x\n", addr + i * 4, sdb->mem_read(addr + i * 4));
  }
  return SIM_STATE::NORMAL;
}
SIM_STATE cmd_p(Sdb *sdb, char *args) { return SIM_STATE::NORMAL; }
SIM_STATE cmd_info(Sdb *sdb, char *args) {
  sdb->cpu_display();
  return SIM_STATE::NORMAL;
}
void Sdb::init() {
  sdb_map_["c"] = cmd_c;
  sdb_map_["si"] = cmd_si;
  sdb_map_["q"] = cmd_q;
  sdb_map_["x"] = cmd_x;
  sdb_map_["p"] = cmd_p;
  sdb_map_["info"] = cmd_info;
}

Sdb::Sdb(Args &args_, Sim *sim_, Memory *mem_)
    : args(args_), sim(sim_), mem(mem_) {
  init();
  if (args.is_diff) {
    diff = new Diff(&sim->cpu);
    diff->init_difftest(diff_file, 1234, args.image);
  }
}

SIM_STATE Sdb::exec_once() {
  SIM_STATE state = sim->exec_once();
  clk_num++;
  if (state == SIM_STATE::QUIT)
    return state;
  if (args.is_diff) {
    if (!diff->difftest_step(1))
      state = SIM_STATE::DIFF_FAILURE;
  }
  return state;
}
int pid_num = 0;
pid_t pids[2] = {};
volatile sig_atomic_t wake_up = 0;
void wakeup_handler(int sig) { wake_up = 1; }
SIM_STATE Sdb::exec(uint32_t n) {
  for (int i = 0; i < n; i++) {
    pid_t pid;
    if (clk_num % 50000 == 0) {
      pid = fork();
      if (pid == 0) {
        signal(SIGUSR1, wakeup_handler);
        while (!wake_up) {
          pause();
        }
        sim->open_wave("chisel.fst");
        while (i < n) {
          SIM_STATE sim_state = exec_once();
          if (sim_state != SIM_STATE::NORMAL) {
            sim->~Sim();
            _exit(0);
          }
        }
      } else {
        if (pid_num == 0) {
          pid_num++;
          pids[0] = pid;
        } else if (pid_num == 1) {
          pid_num++;
          pids[1] = pids[0];
          pids[0] = pid;
        } else if (pid_num == 2) {
          kill(pids[1], SIGKILL);
          pids[1] = pids[0];
          pids[0] = pid;
        }
      }
    }
    SIM_STATE sim_state = exec_once();
    if (sim_state != SIM_STATE::NORMAL) {
      if (sim_state == SIM_STATE::QUIT && !args.is_gtk) {
        if (pid_num == 1)
          kill(pids[0], SIGKILL);
        else {
          kill(pids[1], SIGKILL);
          kill(pids[0], SIGKILL);
        }
      } else {
        if (pid_num == 1)
          kill(pids[0], SIGUSR1);
        else {
          kill(pids[1], SIGUSR1);
          kill(pids[0], SIGKILL);
        }
        wait(NULL);
      }
      return sim_state;
    }
  }
  return SIM_STATE::NORMAL;
}

void Sdb::welcome() {
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to npc\n");
  printf("For help, type \"help\"\n");
}

int Sdb::run() {
  char args_[32];
  char *cmd;
  char *strend;
  std::string line;
  SIM_STATE result;
  if (args.is_batch) {
    result = cmd_c(this, nullptr);
  } else {
    std::cout << "(npc) ";
    while (getline(std::cin, line)) {
      strcpy(args_, line.c_str());
      strend = args_ + strlen(args_);
      cmd = strtok(args_, " ");
      char *sdb_args = cmd + strlen(cmd) + 1;
      if (sdb_args >= strend)
        sdb_args = nullptr;
      uint64_t now = Utils::get_time();
      result = sdb_map_[cmd](this, sdb_args);
      if (result != SIM_STATE::NORMAL) {
        break;
      }
      std::cout << "(npc) ";
    }
  }
  switch (result) {
  case SIM_STATE::QUIT:
    if (sim->cpu.gpr[10] == 0)
      Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN),
          sim->cpu.pc);
    else
      Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),
          sim->cpu.pc);
    break;
  case SIM_STATE::TIMEOUT:
    Log("npc: %s at pc = 0x%08x", ANSI_FMT("TIMEOUT", ANSI_FG_RED),
        sim->cpu.pc);
    break;
  default:
    Log("npc: %s at pc = 0x%08x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),
        sim->cpu.pc);
    break;
  }

  return 0;
}
uint32_t Sdb::mem_read(uint32_t addr) {
  if (mem->in_devide_area(addr))
    diff->difftest_skip = true;
  if (args.is_mtrace)
    printf("pc=0x%x, raddr=0x%x, ", sim->cpu.pc, addr);
  uint32_t rdata = mem->read(addr & ~0x3u);
  if (args.is_mtrace)
    printf("rdata=0x%x\n", rdata);
  return rdata;
}
void Sdb::mem_write(uint32_t addr, uint32_t wdata, char wmask) {
  if (mem->in_devide_area(addr))
    diff->difftest_skip = true;
  if (args.is_mtrace)
    printf("pc=0x%x, waddr=0x%x, wdata=0x%x\n", sim->cpu.pc, addr, wdata);
  mem->write(addr, wdata, wmask);
}
void Sdb::quit() { sim->quit(); }
int Sdb::fetch_inst(int pc) { return mem_read(pc); }
Sdb::~Sdb() {
  if (args.is_diff)
    delete diff;
}
