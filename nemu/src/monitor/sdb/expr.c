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

#include "debug.h"
#include <assert.h>
#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <stdio.h>
#include <string.h>

enum {
  TK_NOTYPE = 256, 
  TK_ADD = 0,
  TK_SUB,
  TK_MUL,
  TK_DIV,
  TK_EQ,
  TK_INT,
  TK_NEG,
  TK_LEFT,
  TK_RIGHT,
  /* TODO: Add more token types */

};

const int prioritys[] = {
  6, 6, 5, 5, 7, 0, 0
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", TK_ADD},         // plus
  {"-", TK_SUB},
  {"\\*", TK_MUL},
  {"/", TK_DIV},
  {"==", TK_EQ},        // equal
  {"[0-9]+", TK_INT},
  {"\\(", TK_LEFT},
  {"\\)", TK_RIGHT},
  {"u", TK_NOTYPE},
};
#define IS_XXX(x, xxx) (x==0 || (tokens[x-1].type==TK_##xxx))
#define OP2(x) (x==0 || (tokens[x-1].type!=TK_INT&&tokens[x-1].type!=TK_RIGHT))
#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[1000] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
          case TK_INT:
            strncpy(tokens[nr_token].str, substr_start, substr_len);
            tokens[nr_token++].type = rules[i].token_type;
            break;
          case TK_ADD:
          case TK_MUL:
          case TK_DIV:
          case TK_LEFT:
          case TK_RIGHT:
          case TK_EQ:
            tokens[nr_token++].type = rules[i].token_type;
            break;
          case TK_SUB:
            if (OP2(nr_token)) {
              tokens[nr_token++].type = TK_NEG;
            }
            else {
              tokens[nr_token++].type = TK_SUB;
            }
          case TK_NOTYPE:
            break;
          default: TODO();
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

bool check_parentheses(int p, int q){
  if (tokens[p].type != TK_LEFT || tokens[q].type != TK_RIGHT) return false;
  int a = 1;
  for (int i = p + 1; i < q; i++) {
    if (tokens[i].type == TK_LEFT) {
      a++;
    }
    else if (tokens[i].type == TK_RIGHT) {
      a--;
    }
    else if (a < 1) {
      return false;
    }
  }
  return true;
}

int main_op(int p, int q){
  int a = 0;
  int priority = 0;
  int op_position = 0;
  for (int i = p; i <= q; i++) {
    if(tokens[i].type == TK_LEFT){
      a++;
    }
    else if(tokens[i].type == TK_RIGHT){
      a--;
    }
    else if(tokens[i].type == TK_NEG){
      continue;
    }
    else if(a==0){
      if(prioritys[tokens[i].type] >= priority){
        op_position = i;
        priority = prioritys[tokens[i].type];
      }
    }
    else if(a < 0){
      printf("Invalid expression\n");
      assert(0);
    }
  }
  return op_position;
}

uint32_t eval(int p, int q){
  if(p > q) assert(0);
  else if(p == q)
  {
    uint32_t num;
    sscanf(tokens[p].str, "%d", &num);
    return IS_XXX(p, NEG) ? -num : num;
  }
  else if (check_parentheses(p, q)) {
    return IS_XXX(p, NEG) ? -eval(p+1, q-1) : eval(p+1, q-1);
  }
  else {
    if (tokens[p].type == TK_NEG) {
      p++;
      return eval(p, q);
    }
    int op = main_op(p, q);
    uint32_t val1 = eval(p, op-1);
    uint32_t val2 = eval(op+1, q);
    switch (tokens[op].type) {
      case TK_ADD: return val1 + val2; break;
      case TK_SUB: return val1 - val2; break;
      case TK_MUL: return val1 * val2; break;
      case TK_DIV: return val1 / val2; break;
    }
  }
  return 0;
}

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  uint32_t result = eval(0, nr_token - 1);
  *success = true;
  /* TODO: Insert codes to evaluate the expression. */
  //TODO();

  return result;
}
