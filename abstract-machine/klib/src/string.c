#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  panic("Not implemented");
}

char *strcpy(char *dst, const char *src) {
  int i = 0;
  for (i = 0; src[i] != 0; i++) {
    dst[i] = src[i];
  }
  dst[i] = 0;
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  panic("Not implemented");
}

char *strcat(char *dst, const char *src) {
  char* dst1 = dst;
  while(*dst != '\0')dst++;
  strcpy(dst, src);
  return dst1;
}

int strcmp(const char *s1, const char *s2) {
  int n = 0;
  while (true) {
    if (s1[n] < s2[n]) return -1;
    else if(s1[n] > s2[n]) return 1;
    else if(s1[n] == '\0') return 0;
    else n++;
  }
}

int strncmp(const char *s1, const char *s2, size_t n) {
  panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
  panic("Not implemented");
}

void *memmove(void *dst, const void *src, size_t n) {
  void* dest = dst;
  if (dst < src) {
  	while (n--){
  	  *(char*)dst = *(char*)src;
      dst++;
      src++;
  	}
  }
  else {
  	while (n--) {
  	  *((char*)dst + n) = *((char*)src + n);
  	}
  }
  return dest;
}

void *memcpy(void *out, const void *in, size_t n) {
  return memmove(out, in, n);
}

int memcmp(const void *s1, const void *s2, size_t n) {
  for(int i = 0; i<n; i++)
  {
    if(((char*)s1)[i] < ((char*)s2)[i]) return -1;
    else if(((char*)s1)[i] > ((char*)s2)[i]) return 1;
    
  }
  return 0;
}

#endif
