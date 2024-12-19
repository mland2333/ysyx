#include <am.h>
#include <ysyxsoc.h>
#include <klib.h>
#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
  /* int i; */
  /* int w = inw(VGACTL_ADDR + 2); */
  /* int h = inw(VGACTL_ADDR);   */
  /* uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR; */
  /* for (i = 0; i < w * h; i ++) fb[i] = i; */
  /* outl(SYNC_ADDR, 1); */
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t width = inw(VGACTL_ADDR+2);
  uint32_t height = inw(VGACTL_ADDR);
  /* printf("width=%d, height=%d\n", width, height); */
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = width, .height = height,
    .vmemsz = 0
  };
  
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  int x = ctl->x;
  int y = ctl->y;
  int w = ctl->w;
  int h = ctl->h;
  int screen_w = inw(VGACTL_ADDR + 2);
  for(uint32_t i = y; i < h + y; i++){
    for(uint32_t j = x; j < w + x; j++){
      uint32_t addr = FB_ADDR+(i*screen_w+j)*4;
      outl(addr,((uint32_t*)ctl->pixels)[(i-y)*w+j-x]);
    }
  }
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
