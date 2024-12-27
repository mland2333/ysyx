#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <string.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char print_buffer[256];
int printf(const char *fmt, ...) {
  va_list ap;
  int count;
  va_start(ap, fmt);
  count = vsprintf(print_buffer, fmt, ap);
  va_end(ap);
  int i = 0;
  while(print_buffer[i])
    putch(print_buffer[i++]);
  return count;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  const char* s = fmt;
  char* str;
  char digits[] = "0123456789abcdef";
  int num;
  unsigned int numu;
  char fill_num = ' ';
  int num_counts = 0;
  char buf[33];
  int count = 0;
  int j = 0;
  while (*s) {
    if (*s == '%') {
      s++;
      if (*s == '0') {
        fill_num = '0';
        s++;
      }
      if('1' <= *s && *s <= '9') {
        num_counts = (int)(*s - '0');
        s++;
      }
      switch (*s) {
        case 'd':
          num = va_arg(ap, int);
          if(num < 0) {
            out[count++] = '-';
            num = -num;
          }
          j = 0;
          do {
            buf[j++] = digits[num%10];
            num /= 10;
          }while (num != 0);
          while (j < num_counts){
            out[count++] = fill_num;
            num_counts--;
          }
          num_counts = 0;
          fill_num = ' ';
          for(; j>0; j--)
            out[count++] = buf[j-1];
          s++;
        break;
        case 's':
          if ((str = va_arg(ap, char*)) == 0) {
            str = "(null)";
          }
          while (*str) {
            out[count++] = *str++;
          }
          s++;
        break;
        case 'x':
          numu = va_arg(ap, uint32_t);
          j = 0;
          do{
            buf[j++] = digits[numu%16];
            numu >>= 4;
          }while(numu != 0);
          for (; j>0; j--) {
            out[count++] = buf[j-1];
          }
          s++;
        break;
        case 'c':
          numu = va_arg(ap, uint32_t);
          out[count++] = (char)numu;
          s++;
        break;
        default:
          return count;
      }
    }
    else {
      out[count++] = *s++;
    }
  }
  out[count] = 0;
  return count;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  return vsprintf(out, fmt, ap);
  va_end(ap);
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
