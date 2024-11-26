#include <cstdint>
#include <cstdio>
#include <iostream>
#include <sdb.h>
#include <device/device.h>
extern Sdb* sdb;

extern "C" int inst_fetch(int pc){
  return sdb->inst_fetch(pc);
}
extern "C" void quit(){
  sdb->quit();
}

uint64_t rtc_time = 0;
extern uint32_t sync_update;
extern "C" int pmem_read(int raddr){
  if (raddr == RTC_ADDR + 4){
    rtc_time = sdb->get_rtc();
    sdb->diff_skip_step(); 
    return (int)(rtc_time >> 32);
  }
  else if(raddr == RTC_ADDR){
    sdb->diff_skip_step();
    return (int)rtc_time;
  }
  if(raddr == VGACTL_ADDR){
    sdb->diff_skip_step();
    return SCREEN_H;
  }
  else if(raddr == VGACTL_ADDR + 2){
    sdb->diff_skip_step();
    return SCREEN_W << 16;
  }
  else if(raddr == VGACTL_ADDR + 4){
    sdb->diff_skip_step();
    return sync_update;
  }
  return sdb->mem_read(raddr);
}
extern "C" void pmem_write(uint32_t waddr, int wdata, char wmask){
  if (waddr == SERIAL_PORT) {
    sdb->diff_skip_step();
    std::cout << (char)wdata << std::flush;
    return;
  }
  if(waddr == VGACTL_ADDR + 4){
    sdb->diff_skip_step();
    sync_update = wdata;
    return;
  }
  else if (waddr >= FB_ADDR && waddr < FB_ADDR + SCREEN_SIZE) {
    sdb->diff_skip_step();
    set_vga_buf(waddr, wdata);
    return;
  }
  sdb->mem_write(waddr, wdata, wmask & 0x0f);
}
extern "C" void difftest(){
  sdb->difftest();
}
