#include <unistd.h>
#include <stdio.h>
#include <sys/time.h>
int main() {
  struct timeval st;
  intptr_t now = 0;
  while (1) {
    gettimeofday(&st, NULL);
    if (st.tv_usec - now >= 500000) {
      printf("timer\n");
      now = st.tv_usec;
    }
  }
  
  return 0;
}
