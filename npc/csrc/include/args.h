#pragma once
#include <cstddef>
#include <cstdlib>
#include <getopt.h>
#include <cstdio>
class Args{
public:
  char* gtk_file = nullptr;
  char* image = nullptr;
  bool is_nvboard = false;
  bool is_gtk = false;
  bool is_batch = false;
  bool is_itrace = false;
  bool is_ftrace = false;
  bool is_diff = false;

  Args(int argc, char* argv[]){
    constexpr struct option table[] = {
      {"batch", no_argument, NULL, 'b'},
      {"log", required_argument, NULL, 'l'},
      {"diff", no_argument, NULL, 'd'},
      {"port", required_argument, NULL, 'p'},
      {"ftrace", no_argument, NULL, 'f'},
      {"gtktrace", no_argument, NULL, 'g'},
      {"nvboard", no_argument, NULL, 'n'},
      {"itrace", no_argument, NULL, 'i'},
      {"help", no_argument, NULL, 'h'},
      {0, 0, NULL, 0},
  };
  int o;
  while ((o = getopt_long(argc, argv, "-bhnigdf", table, NULL)) != -1) {
    switch (o) {
    case 'g':
      is_gtk = true;
      break;
    case 'n':
      is_nvboard = true;
      break;
    case 'b':
      is_batch = true;
      break;
    case 'i':
      is_itrace = true;
      break;
    case 'f':
      is_ftrace = true;
      break;
    case 'd':
      is_diff = true;
      break;
    case 1:
      image = optarg;
    break;
    default:
      printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
      printf("\t-b,--batch              run with batch mode\n");
      printf("\t-l,--log=FILE           output log to FILE\n");
      printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
      printf("\t-g,--gtktrace           run with gtktrace\n");
      printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
      printf("\n");
      exit(-1);
    }
  }
  return;
  }
};
