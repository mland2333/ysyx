#include <cstdint>
#include <cstdio>
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
extern "C" int pmem_read(int raddr){
  if (raddr == RTC_ADDR + 4){
    rtc_time = sdb->get_rtc();
    return (int)(rtc_time >> 32);
  }
  else if(raddr == RTC_ADDR)
    return (int)rtc_time;

  if(raddr == VGACTL_ADDR){
    return SCREEN_H;
  }
  else if(raddr == VGACTL_ADDR + 2){
    return SCREEN_W;
  }
  return sdb->mem_read(raddr & ~0x3u);
}

extern "C" void pmem_write(int waddr, int wdata, char wmask){
  if (waddr == SERIAL_PORT) {
    putchar(wdata);
    return;
  }
  if(waddr == VGACTL_ADDR + 4){
    vga_sync(wdata);
    return;
  }
  else if (waddr >= FB_ADDR && waddr < FB_ADDR + SCREEN_SIZE) {
    set_vga_buf(waddr, wdata);
    return;
  }
  sdb->mem_write(waddr & ~0x3u, wdata, wmask & 0x0f);
}
