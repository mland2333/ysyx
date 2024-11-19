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
extern uint32_t sync_update;
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
    /* printf("read addr: 0x%x, rdata: %d\n", raddr, SCREEN_W); */
    return SCREEN_W << 16;
  }
  else if(raddr == VGACTL_ADDR + 4){
    return sync_update;
  }

  return sdb->mem_read(raddr & ~0x3u);
}

extern "C" void pmem_write(uint32_t waddr, int wdata, char wmask){
  /* printf("write addr: 0x%x, wdata: %d\n", waddr, wdata); */
  if (waddr == SERIAL_PORT) {
    putchar(wdata);
    return;
  }
  if(waddr == VGACTL_ADDR + 4){
    
    sync_update = wdata;
    return;
  }
  else if (waddr >= FB_ADDR && waddr < FB_ADDR + SCREEN_SIZE) {
    /* printf("write addr: 0x%x, wdata: %d\n", waddr, wdata); */
    set_vga_buf(waddr, wdata);
    return;
  }
  sdb->mem_write(waddr & ~0x3u, wdata, wmask & 0x0f);
}
