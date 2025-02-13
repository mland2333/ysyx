#pragma once
#include <common.h>

#define time_t intptr_t
#define suseconds_t intptr_t

struct timeval {
    time_t tv_sec;  // 秒（从 1970-01-01 00:00:00 UTC 到现在的秒数）
    suseconds_t tv_usec; // 微秒（0~999999）
};
