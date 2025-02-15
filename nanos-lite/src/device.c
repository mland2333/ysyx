#include <common.h>
#include <stdio.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  for(int i = 0; i<len; i++)
    putch(((char*)buf)[i]);
  return len;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if (ev.keycode == AM_KEY_NONE) return 0;
  return sprintf((char *)buf, "k%c %s", ev.keydown ? 'd' : 'u', keyname[ev.keycode]);
}
static int width;
static int height;
size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  width = io_read(AM_GPU_CONFIG).width;
  height = io_read(AM_GPU_CONFIG).height;
  return sprintf(buf, "WIDTH: %d\nHEIGHT: %d\n", width, height);
}

size_t fb_write(void *buf, size_t offset, size_t len) {
  int y = (offset / 4) / width;
  int x = (offset / 4) % width;
  io_write(AM_GPU_FBDRAW, x, y, buf, len / 4, 1, true);
  return 0;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
