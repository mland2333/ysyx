#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <fcntl.h>
static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;

uint32_t NDL_GetTicks() {
  struct timeval st;
  gettimeofday(&st, NULL);
  return st.tv_usec / 1000;
}

int NDL_PollEvent(char *buf, int len) {
  int fd = open("/dev/event", 0, 0);
  int ret = read(fd, buf, len);
  close(fd);
  if (ret != 0) return 1;
  else return 0;
}

void NDL_OpenCanvas(int *w, int *h) {
  FILE *file = fopen("/proc/displayinfo", "r");
  char line[100];  // 存储每一行
  int width = 0, height = 0;

  while (fgets(line, sizeof(line), file)) {
    if (strncmp(line, "WIDTH", 5) == 0) {
      sscanf(line, "WIDTH : %d", &width);  // 处理 "WIDTH :    640"
    } else if (strncmp(line, "HEIGHT", 6) == 0) {
      sscanf(line, "HEIGHT: %d", &height); // 处理 "HEIGHT:  480"
    }
  }
  printf("WIDTH=%d, HEIGHT=%d\n", width, height);
  fclose(file);
  if (getenv("NWM_APP")) {
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  return 0;
}

void NDL_Quit() {
}
