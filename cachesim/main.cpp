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
  float tmts[3] = {65.88, 89.6, 138.84};
  std::vector<int> tag_array;
  std::vector<char> valid_array;
  std::vector<char> replace_ways;
  std::vector<std::vector<int>> lru_counter;
  Cache(int num_blocks_, int num_ways_, int data_width_)
  :num_blocks(num_blocks_), num_ways(num_ways_), data_width(data_width_){
    num_sets = num_blocks / num_ways;
    tag_array.resize(num_blocks);
    valid_array.resize(num_blocks);
    replace_ways.resize(num_blocks);
    lru_counter.resize(num_sets, std::vector<int>(num_ways));
    for (auto&valid : valid_array)
      valid = 0;

    for(int i = 0; i < num_sets; i++) {
      for(int j = 0; j < num_ways; j++) {
        lru_counter[i][j] = j; // 设置初始LRU状态
      }
    }
    for(int i = 0; i<num_sets; i++)
      replace_ways[i*num_ways] = true;
    offest_width = static_cast<int>(std::log2(data_width));
    index_width = static_cast<int>(std::log2(num_sets));
  }
  void sim(uint32_t pc){
    if(pc >= 0x0f000000 && pc < 0x0f002000 || pc < 0xa0000000) return;
    uint32_t index = (pc >> offest_width) & ~(0xffffffff << index_width);
    uint32_t tag = pc & (0xffffffff << (offest_width + index_width));
    for(int i = 0; i<num_ways; i++){
      if(valid_array[index*num_ways+i] && tag_array[index*num_ways+i] == tag){
        hit_counter++;
        /* update_lru(index, i); */
        return;
      }
    }
    /* int lru_way = find_lru(index); // 找到LRU方式 */
    /* valid_array[index*num_ways + lru_way] = true; */
    /* tag_array[index*num_ways + lru_way] = tag; */
    /* update_lru(index, lru_way); // 更新LRU状态 */

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
  void update_lru(int index, int used_way) {
    for(int i = 0; i < num_ways; i++) {
      if(i!=used_way) {
        lru_counter[index][i]++; // 增加其他的计数
      }
    }
    lru_counter[index][used_way] = 0; // 最近使用的设为0
  }

  int find_lru(int index) {
    int lru_way = 0;
    int max_count = -1;
    for(int i = 0; i < num_ways; i++) {
      if(lru_counter[index][i] > max_count) {
        max_count = lru_counter[index][i];
        lru_way = i;
      }
    }
    return lru_way;
  }

  void statistic(){
    std::cout << std::format("hit_counter = {}, miss_counter = {}, amat = {}\n", hit_counter, miss_counter, 2+(float)miss_counter/(miss_counter+hit_counter)*tmts[offest_width-2]);
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
