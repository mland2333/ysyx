#include <csignal>
#include <exception>
#include <iostream>
#include <memory>
#include <simulator.h>
#include <area.hpp>
#include <memory.h>
#include <args.h>
#include <sdb.h>
#include <utils.h>
Sdb* sdb;
Simulator* sim;

void signalHandler(int signum) {
    sim->~Simulator();
    sdb->~Sdb();
    std::exit(signum);  // 正常退出并调用析构函数
}
int main(int argc, char **argv) {
  std::signal(SIGINT, signalHandler);
  std::signal(SIGSEGV, signalHandler);
  std::signal(SIGABRT, signalHandler);
  Verilated::commandArgs(argc, argv);

  Args args(argc, argv);
  Memory mem(args);
  auto msim = std::make_unique<Simulator>(args);
  sim = msim.get();
  auto msdb = std::make_unique<Sdb>(args, sim, &mem);
  sdb = msdb.get();

  Verilated::commandArgs(argc, argv);
  try{
    sim->reset(20);
    sdb->welcome();
    sdb->run();
  } catch (const std::exception& e){
    std::cerr << "Caught exception: " << e.what() << std::endl;
  }
  return 0;
}
