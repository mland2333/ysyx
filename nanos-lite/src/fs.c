#include <fs.h>
#include <stdio.h>
#include <string.h>

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  ReadFn read;
  WriteFn write;
  size_t open_offset;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
extern size_t serial_write(const void *buf, size_t offset, size_t len);
extern size_t events_read(void *buf, size_t offset, size_t len);
extern size_t dispinfo_read(void *buf, size_t offset, size_t len);
extern size_t fb_write(const void *buf, size_t offset, size_t len);
static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write},
  [FD_FB] = {"/dev/fb", 0, 0, invalid_read, fb_write},
#include "files.h"
  {"/dev/events", 0, 0, events_read, invalid_write},
  {"/proc/dispinfo", 0, 0, dispinfo_read, invalid_write},
  
};


#define FILES_NUM (sizeof(file_table) / sizeof(file_table[0]))

const char* get_file_name_by_fd(int fd){
  assert(fd >= 0 && fd < FILES_NUM);
  return file_table[fd].name;
}
int get_file_fd_by_name(const char* name){
  for (int i = 0; i < FILES_NUM; i++) {
    if(strcmp(name, file_table[i].name) == 0) return i;
  }
  assert(0);
  return -1;
}
int fs_open(const char *pathname, int flags, int mode){
  for (int i = 0; i < FILES_NUM; i++) {
    if(strcmp(pathname, file_table[i].name) == 0) {
      /* printf("open %s %d\n", pathname, i); */
      return i;
    }
  }
  assert(0);
  return -1;
}
extern size_t ramdisk_read(void*, size_t, size_t);
size_t fs_read(int fd, void *buf, size_t len){
  assert(fd >= 0 && fd < FILES_NUM);
  size_t offset = file_table[fd].disk_offset;
  size_t open_offset = file_table[fd].open_offset;
  if (file_table[fd].read != NULL){
    return file_table[fd].read(buf, open_offset, len);
  }
  /* if((open_offset + len) <= file_table[fd].size) */
      /* len = file_table[fd].size - open_offset; */
  /* assert((open_offset + len) <= file_table[fd].size); */
  ramdisk_read(buf, offset + open_offset, len);
  file_table[fd].open_offset += len;
  return len;
}
size_t fs_lseek(int fd, size_t offset, int whence){
  assert(offset <= file_table[fd].size);
  switch (whence) {
    case SEEK_SET: file_table[fd].open_offset = offset; break;
    case SEEK_CUR:
      if((file_table[fd].open_offset + offset) > file_table[fd].size)
        printf("offset = %d, offset = %d, size = %d\n", file_table[fd].open_offset, offset, 
           file_table[fd].size);
      /* assert((file_table[fd].open_offset + offset) <= file_table[fd].size); */
      file_table[fd].open_offset += offset;
      break;
    case SEEK_END: 
      file_table[fd].open_offset = file_table[fd].size - offset;
      break;
    default:
      assert(0);
  }
  return file_table[fd].open_offset;
}
extern size_t ramdisk_write(const void *buf, size_t offset, size_t len);
size_t fs_write(int fd, const void *buf, size_t len){
  assert(fd >= 0 && fd < FILES_NUM);
  size_t offset = file_table[fd].disk_offset;
  size_t open_offset = file_table[fd].open_offset;
  if (file_table[fd].write != NULL){
    return file_table[fd].write(buf, open_offset, len);
  }
  /* if((open_offset + len) <= file_table[fd].size) */
    /* len = file_table[fd].size - open_offset; */
  /* assert((open_offset + len) <= file_table[fd].size); */
  ramdisk_write(buf, offset + open_offset, len);
  file_table[fd].open_offset += len;
  return len;
}
int fs_close(int fd){
    /* printf("close %s %d\n", file_table[fd].name, fd); */
    file_table[fd].open_offset = 0;
    return 0;
}

void init_fs() {
  int w = io_read(AM_GPU_CONFIG).width;
  int h = io_read(AM_GPU_CONFIG).height;
  int fd = get_file_fd_by_name("/dev/fb");
  file_table[fd].size = w * h * sizeof(int);
  /* printf("size = %d\n", file_table[fd].size); */
}
