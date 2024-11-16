#include <memory.hpp>
#include <string>
#include <sys/types.h>
#include <fstream>
#include <filesystem>

Memory::Memory(){
  base_ = 0x80000000;
  size_ = 0x1000000;
  mem_ = new char[size_];
  init();
}
Memory::Memory(uint32_t base, uint32_t size) : base_(base), size_(size){
  mem_ = new char[size_];
  init();
}
Memory::Memory(uint32_t base, uint32_t size, const char* image) : base_(base), size_(size){
  mem_ = new char[size_];
}

long Memory::load_img(const char* image){
  if (image == nullptr) {
    std::cout << "No image is given. Use the default built-in image.\n";
    return 4096;
  }
  std::string img_file(image);
  std::filesystem::path img_path(img_file);
  if (!std::filesystem::exists(img_path)) {
    std::cout << "Cannot open '" << img_file << "'\n";
    return -1;
  }
  std::cout << "打开文件" << img_file << '\n';
  long size = std::filesystem::file_size(img_path);
  std::ifstream file(image, std::ios::binary);

  file.read(mem_, size);
  return size;
}

Memory::~Memory(){
  delete[] mem_;
}
