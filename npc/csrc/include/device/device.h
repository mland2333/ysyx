#pragma once
#include <cstdint>

#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0000200)
#define DISK_ADDR       (DEVICE_BASE + 0x0000300)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

#define SCREEN_W 800
#define SCREEN_H 600
#define SCREEN_SIZE (SCREEN_H*SCREEN_W*sizeof(uint32_t))

#define TIMER_HZ 60

void init_vga();
uint32_t get_vga_buf(uint32_t raddr);
void set_vga_buf(uint32_t waddr, int wdata);
void vga_update_screen();

int device_update();
