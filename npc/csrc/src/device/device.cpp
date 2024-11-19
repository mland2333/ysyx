#include <device/device.h>
#include <utils.h>
#include <SDL2/SDL.h>
int device_update(){
  static uint64_t last = 0;
  uint64_t now = Utils::get_time();
  if (now - last < 1000000 / TIMER_HZ) {
    return 0;
  }
  last = now;

  vga_update_screen();

  SDL_Event event;

  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_QUIT:
        return -1;
      break;
      default:
      break;
    }
  }
  return 0;
}
