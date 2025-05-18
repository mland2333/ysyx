#include <device/device.h>
#include <cstdint>
#include <SDL2/SDL.h>
#include <cstdio>
#include <cstring>
static void *vmem = nullptr;

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

static void init_screen() {
  SDL_Window *window = NULL;
  char title[128];
  sprintf(title, "riscve-npc");
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(
      SCREEN_W,
      SCREEN_H,
      0, &window, &renderer);
  SDL_SetWindowTitle(window, title);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
  SDL_RenderPresent(renderer);
}

static inline void update_screen() {
  SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}

uint32_t sync_update = 0;
void vga_update_screen() {
  if(sync_update == 1){
    update_screen();
  }
}

void init_vga() {
  vmem = malloc(SCREEN_SIZE);
  init_screen();
  memset(vmem, 0, SCREEN_SIZE);
}

uint32_t get_vga_buf(uint32_t raddr){
  return ((uint32_t*)vmem)[(raddr-FB_ADDR)/4];
}

void set_vga_buf(uint32_t waddr, int wdata){
  ((uint32_t*)vmem)[(waddr-FB_ADDR)/4] = wdata;
}
