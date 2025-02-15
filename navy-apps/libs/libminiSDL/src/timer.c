#include <NDL.h>
#include <sdl-timer.h>
#include <stdio.h>
uint32_t init_timer = 0;
SDL_TimerID SDL_AddTimer(uint32_t interval, SDL_NewTimerCallback callback, void *param) {
  return NULL;
}

int SDL_RemoveTimer(SDL_TimerID id) {
  return 1;
}

uint32_t SDL_GetTicks() {
  return NDL_GetTicks() - init_timer;
}

void SDL_Delay(uint32_t ms) {
}
