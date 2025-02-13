#include <unistd.h>
#include <stdio.h>
#include <sys/time.h>
#include <NDL.h>
int main() {
  intptr_t now = 0;
  /* struct timeval st; */
  /* while (1) { */
  /*   gettimeofday(&st, NULL); */
  /*   if ((st.tv_usec - now) >= 500000) { */
  /*     printf("timer\n"); */
  /*     now = st.tv_usec; */
  /*   } */
  /* } */
  intptr_t old = 0;
  while(1){
    now = NDL_GetTicks();
    if ((now - old) >= 5000){
      printf("timer\n");
      old = now;
    }
  }
  
  return 0;
}
