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

#include "sdb.h"

#define NR_WP 32

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

WP* new_wp(){
  if(free_){
    WP* temp = free_;
    free_ = free_->next;
    temp->next = NULL;
    if(!head) head = temp;
    else {
      temp->next = head->next;
      head->next = temp;
    }
    return temp;
  }
  else assert(0);
  return NULL;
}

void free_wp(WP* wp){
  if(wp==NULL) return;
  if(wp == head){
    head = head->next;
  }
  else {
    WP* temp = head;
    while(temp && temp->next != wp)
      temp = temp->next;
    if(!temp) return;
    temp->next = wp->next;
  }
  if(free_ == NULL) {
    wp->next = NULL;
    free_ = wp;
  }
  else {
    wp->next = free_->next;
    free_->next = wp;
  }
}

WP* get_wp(int NO){
  if(NO < NR_WP)
    return &wp_pool[NO];
  else return NULL;
}
WP* get_head(){
  return head;
}
void print_wp(){
  WP* wp = head;
  while (wp) {
    printf("Watchpoint %d, expression: %s, value: %d\n", wp->NO, wp->expression, wp->value);
    wp = wp->next;
  }
}
/* TODO: Implement the functionality of watchpoint */

