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
  Verilated::commandArgs(argc, argv);
  Args args(argc, argv);
  Area psram("psram", 0x80000000, 0x400000);
  /* Area mrom("mrom", 0x20000000, 0x1000, args.image); */
  Area mrom("mrom", 0x20000000, 0x10000);
  /* Area flash("flash", 0x30000000, 0x10000000); */
  Area flash("flash", 0x30000000, 0x10000000, args.image);
  /* *(int*)flash.mem_ = 0x12345678; */
  /* Utils::load_img(flash.mem_, "/home/mland/ysyx-workbench/am-kernels/tests/cpu-tests/build/char-test.bin"); */
  Memory mem({&psram, &mrom, &flash});
  auto msim = std::make_unique<Simulator>(args);
  sim = msim.get();
  Verilated::commandArgs(argc, argv);
  sim->reset(20);
  Verilated::commandArgs(argc, argv);
  auto msdb = std::make_unique<Sdb>(args, sim, &mem);
  try{
    sdb = msdb.get();
    sdb->welcome();
    sdb->run();
  } catch (const std::exception& e){
    std::cerr << "Caught exception: " << e.what() << std::endl;
  }
  return 0;
}
