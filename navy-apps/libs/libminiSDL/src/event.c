#include <NDL.h>
#include <SDL.h>
#include <stdio.h>
#include <string.h>
#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  char buf[64];
  int ret;
  char is_down;
  char name[32];
  if ((ret = NDL_PollEvent(buf, 64)) == 1) {
    sscanf(buf, "k%c %s", &is_down, name);
    ev->type = is_down == 'd' ? SDL_KEYDOWN : SDL_KEYUP;
    int key_num = sizeof(keyname) / sizeof(keyname[0]);
    for (int i = 0; i < key_num; i++) {
      if(strcmp(name, keyname[i]) == 0) {
        ev->key.keysym.sym = i;
        return 1;
      }
    }
  }
  ev->key.keysym.sym = SDLK_NONE;
  return 0;
}

int SDL_WaitEvent(SDL_Event *event) {
  char buf[64];
  NDL_WaitEvent(buf, 64);

  char is_down;
  char name[32];
  sscanf(buf, "k%c %s", &is_down, name);
  event->type = is_down == 'd' ? SDL_KEYDOWN : SDL_KEYUP;
  int key_num = sizeof(keyname) / sizeof(keyname[0]);
  for (int i = 0; i < key_num; i++) {
    if(strcmp(name, keyname[i]) == 0) {
      event->key.keysym.sym = i;
      return 1;
    }
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
