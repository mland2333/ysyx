#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <string.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  const char* s = fmt;
  char* str;
  char digits[] = "0123456789abcdef";
  int num;
  char buf[33];
  int count = 0;
  while (*s) {
    if (*s == '%') {
      s++;
      switch (*s) {
        case 'd':
          num = va_arg(ap, int);
          if(num < 0) {
            out[count++] = '-';
            num = -num;
          }
          int j = 0;
          do {
            buf[j++] = digits[num%10];
            num /= 10;
          }while (num != 0);
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
