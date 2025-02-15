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
  int fd = open("/dev/events", O_RDONLY);
  int ret = read(fd, buf, len);
  close(fd);
  if(ret == 0) return 0;
  /* printf("%s\n", buf); */
  return 1;
}

int NDL_WaitEvent(char *buf, int len) {
  int fd = open("/dev/events", O_RDONLY);
  int ret;
  while ((ret = read(fd, buf, len)) == 0);
  close(fd);
  return 1;
}


void NDL_OpenCanvas(int *w, int *h) {
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
  int fd = open("/proc/dispinfo", O_RDONLY); 
  char buffer[1024];  
  ssize_t bytesRead = read(fd, buffer, sizeof(buffer) - 1);
  close(fd);  
  buffer[bytesRead] = '\0';
  int width = 0, height = 0;
  sscanf(buffer, "WIDTH: %d\nHEIGHT: %d\n", &width, &height);
  /* printf("WIDTH=%d, w=%d, HEIGHT=%d, h=%d\n", width, w, height, h); */
  fd = open("/dev/fb", 0);
  /* for (int i = 0; i<h; i++) */
  /*   for (int j = 0; j<w; i++) */
  /*     printf("%d ", i*w+j); */
  /* printf("\n"); */
  if (w==0) w = width;
  if (h==0) h = height;
  for (int i = 0; i<h && i < height; i++){
    lseek(fd, ((y+i)*width+x)*4, SEEK_SET);
    write(fd, (void*)(pixels + i*w), w*sizeof(int));
  }
  close(fd);
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
