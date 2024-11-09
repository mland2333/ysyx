/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>
// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";
int buf_i = 0;
const static char* nums = "0123456789";
const static char* ops = "+-*/";
static void gen_num(){
  if(rand()%2 == 1){
    buf[buf_i++] = '-';
    buf[buf_i++] = nums[rand()%10];
    buf[buf_i++] = 'u';
  }
  else {
    buf[buf_i++] = nums[rand()%10];
    buf[buf_i++] = 'u';
  }
}
static void gen(char c){
  buf[buf_i++] = c;
}
static void gen_rand_op(){
  buf[buf_i++] = ops[rand()%4];
}

static void gen_rand_expr() {
  if (buf_i > 50){
    gen_num();
    return;
  }
  switch (rand() % 4) {
    case 0 : gen_num(); break;
    case 1 : gen('('); gen_rand_expr(); gen(')'); break;
    case 2 : gen(' '); gen_rand_expr(); break;
    default: gen_rand_expr(); gen_rand_op(); gen_rand_expr(); break;
  }
}


int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i = 0;
  while(i < loop){
    buf_i = 0;
    gen_rand_expr();
    buf[buf_i] = 0;
    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr -Werror ");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
    i++;
  }
  return 0;
}
