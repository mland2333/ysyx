#include <NDL.h>
#include <SDL.h>
#include <stdio.h>
#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  return 0;
}

int SDL_WaitEvent(SDL_Event *event) {
  char buf[64];
  int ret;
  if ((ret = NDL_PollEvent(buf, 64)) == 1) {
    if (buf[1] == 'u') event->type = SDL_KEYUP;
    else if(buf[2] == 'd') event->type = SDL_KEYDOWN;
    sscanf(buf+2, "%c", &event->key.keysym.sym);
    printf("%s", buf);
    return 1;
  }
  event->key.keysym.sym = SDLK_NONE;
  return 0;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  return NULL;
}
