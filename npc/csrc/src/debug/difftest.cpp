#include <debug/difftest.h>
#include <debug/log.h>
#include <cstdio>
#include <dlfcn.h>
#include <cstdint>
#include <assert.h>
#include <iostream>
void (*ref_difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = nullptr;
void (*ref_difftest_regcpy)(void *dut, bool direction) = nullptr;
void (*ref_difftest_exec)(uint64_t n) = nullptr;

void Diff::init_difftest(const char *ref_so_file, int port){
  assert(ref_so_file != nullptr);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = reinterpret_cast<void (*)(uint64_t, void*, size_t, bool)>(dlsym(handle, "difftest_memcpy"));
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = reinterpret_cast<void (*)(void*, bool)>(dlsym(handle, "difftest_regcpy"));
  assert(ref_difftest_regcpy);

  ref_difftest_exec = reinterpret_cast<void (*)(uint64_t)>(dlsym(handle, "difftest_exec"));
  assert(ref_difftest_exec);


  void (*ref_difftest_init)(int) = reinterpret_cast<void (*)(int)>(dlsym(handle, "difftest_init"));
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(0x20000000, (void*)area_->mem_, area_->img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy((void*)cpu_, DIFFTEST_TO_REF);
}

bool Diff::difftest_step() {
  if (first_inst) {
    ref_difftest_regcpy((void*)cpu_, DIFFTEST_TO_REF);
    first_inst = false;
    return true;
  }
  if (diff_skip){
    ref_difftest_regcpy((void*)cpu_, DIFFTEST_TO_REF);
    diff_skip = diff_skip_buf;
    return true;
  }
  if (diff_skip_buf) {
    diff_skip = true;
    diff_skip_buf = false;
    return true;
  }
  diff_nums ++;
  /* std::cout << "diff\n"; */
  ref_difftest_exec(1);
  ref_difftest_regcpy((void*)ref_cpu, DIFFTEST_TO_DUT);
  int i;
  if((i = cpu_->check(ref_cpu)) != 0){
    if (i == -1) {
      printf("difftest失败, 寄存器为：pc, 地址：0x%x\ncpu.pc = 0x%x\nref_gpr.pc = 0x%x\n",
          cpu_->pc, cpu_->pc, ref_cpu->pc);
    }
    else {
      printf("difftest失败, 寄存器为：%s, 地址：0x%x\ncpu.gpr[%d] = 0x%x\nref_gpr[%d] = 0x%x\n",
           RegName::regs[i], cpu_->pc, i, cpu_->gpr[i], i, ref_cpu->gpr[i]);
    }
    return false;
  }
  return true;
}
