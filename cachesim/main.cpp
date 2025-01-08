#include <cmath>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <string>
#include <vector>
#include <format>
#include <iostream>


class Cache{
public:
  int num_blocks;
  int num_ways;
  int num_sets;
  int offest_width;
  int index_width;
  int data_width = 4;
  uint32_t hit_counter = 0;
  uint32_t miss_counter = 0;
  std::vector<int> tag_array;
  std::vector<char> valid_array;
  std::vector<char> replace_ways;
  Cache(int num_blocks_, int num_ways_, int data_width_)
  :num_blocks(num_blocks_), num_ways(num_ways_), data_width(data_width_){
    num_sets = num_blocks / num_ways;
    tag_array.resize(num_blocks);
    valid_array.resize(num_blocks);
    replace_ways.resize(num_blocks);
    for (auto&valid : valid_array)
      valid = 0;
    for(int i = 0; i<num_sets; i++)
      replace_ways[i*num_ways] = true;
    offest_width = static_cast<int>(std::log2(data_width));
    index_width = static_cast<int>(std::log2(num_sets));
    /* std::cout<<std::format("INDEX_WADTH = {}\nOFFEST_WIDTH = {}\n", index_width, offest_width); */
    /* std::cout << std::format("{} {}\n", num_blocks, num_ways); */
  }
  void sim(uint32_t pc){
    /* std::cout << std::format("{}\n", pc); */
    if(pc >= 0x0f000000 && pc < 0x0f002000 || pc < 0xa0000000) return;
    uint32_t index = (pc >> offest_width) & ~(0xffffffff << index_width);
    /* std::cout << std::format("{}\n", index); */
    uint32_t tag = pc & (0xffffffff << (offest_width + index_width));
    /* std::cout << std::format("{}\n", tag); */
    for(int i = 0; i<num_ways; i++){
      if(valid_array[index*num_ways+i] && tag_array[index*num_ways+i] == tag){
        hit_counter++;
        return;
      }
    }
    for(int i = 0; i < num_ways; i++){
      if(replace_ways[index*num_ways+i]){
        valid_array[index*num_ways+i] = true;
        tag_array[index*num_ways+i] = tag;
        replace_ways[index*num_ways+i] = false;
        if(i == num_ways-1)
          replace_ways[index*num_ways] = true;
        else 
          replace_ways[index*num_ways+i+1] = true;
        break;
      }
    }
    miss_counter++;
  }
  void statistic(){
    std::cout << std::format("hit_counter = {}, miss_counter = {}\n", hit_counter, miss_counter);
  }
};

int main(int argc, char* argv[]){
  char* filename = argv[1];
  int num_blocks = std::stoi(argv[2], nullptr, 10);
  int num_ways = std::stoi(argv[3], nullptr, 10);
  int data_width = std::stoi(argv[4], nullptr, 10);
  std::ifstream itrace(filename, std::ios::binary);
  std::vector<int> pcs;
  std::string line;
  Cache mcache(num_blocks, num_ways, data_width);
  uint32_t pc;
  itrace.read((char*)&pc, sizeof(pc));
  while(!itrace.eof()){
    pcs.push_back(pc);
    itrace.read((char*)&pc, sizeof(pc));
  }
  itrace.close();
  for (auto pc : pcs) {
    mcache.sim(pc);
  }
  mcache.statistic();
}
