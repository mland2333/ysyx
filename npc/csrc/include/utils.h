#pragma once

#include <cstdint>
#include <chrono>
#include <iostream>
#include <filesystem>
#include <fstream>
namespace Utils{

inline uint64_t get_time(){
  auto now = std::chrono::system_clock::now();
  return (std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch())).count();
}
inline long load_img(char* mem_, const char* image){
  if (image == nullptr) {
    std::cout << "No image is given. Use the default built-in image.\n";
    return 4096;
  }
  long image_size;
  std::string img_file(image);
  std::filesystem::path img_path(img_file);
  if (!std::filesystem::exists(img_path)) {
    std::cout << "Cannot open '" << img_file << "'\n";
    return 0;
  }
  /* std::cout << "打开文件" << img_file << '\n'; */
  image_size = std::filesystem::file_size(img_path);
  std::ifstream file(image, std::ios::binary);

  file.read(mem_, image_size);
  return image_size;
}
}
