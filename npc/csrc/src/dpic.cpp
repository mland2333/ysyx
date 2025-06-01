#include <cstdint>
#include <cstdio>
#include <device/device.h>
#include <iostream>
#include <sdb.h>
extern Sdb *sdb;

extern "C" void quit() { sdb->quit(); }

uint64_t rtc_time = 0;
extern uint32_t sync_update;
extern "C" int pmem_read(int raddr) {
  if (raddr == VGACTL_ADDR) {
    sdb->diff_skip_step();
    return SCREEN_H;
  } else if (raddr == VGACTL_ADDR + 2) {
    sdb->diff_skip_step();
    return SCREEN_W << 16;
  } else if (raddr == VGACTL_ADDR + 4) {
    sdb->diff_skip_step();
    return sync_update;
  }
  return sdb->mem_read(raddr);
}
extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  if (waddr == VGACTL_ADDR + 4) {
    sdb->diff_skip_step();
    sync_update = wdata;
    return;
  } else if (waddr >= FB_ADDR && waddr < FB_ADDR + SCREEN_SIZE) {
    sdb->diff_skip_step();
    set_vga_buf(waddr, wdata);
    return;
  }
  sdb->mem_write(waddr, wdata, wmask & 0x0f);
}
extern "C" void difftest() { sdb->difftest(); }

extern "C" void diff_skip() { sdb->diff_skip_step(); }
extern "C" void flash_read(int32_t addr, int32_t *data) {
  /* printf("flash_read 0x%x\n", addr); */
  *data = sdb->mem_read(addr + 0x30000000);
}
extern "C" void mrom_read(int32_t addr, int32_t *data) {
  *data = sdb->mem_read(addr);
}

extern "C" void fetch_inst() { sdb->fetch_inst(); }

extern "C" void update_reg(int32_t rd, int32_t wdata) { sdb->update_reg(rd, wdata); }
extern "C" void update_pc(int32_t pc) { sdb->update_pc(pc); }
extern "C" void update_inst(int32_t inst) { sdb->update_pc(inst); }
