#pragma once

#include <chrono>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
namespace Utils {

inline uint64_t get_time() {
  auto now = std::chrono::system_clock::now();
  return (std::chrono::duration_cast<std::chrono::microseconds>(
              now.time_since_epoch()))
      .count();
}
inline uint64_t img_size(const char *image) {
  if (image == nullptr)
    return 0;
  std::string img_file(image);
  std::filesystem::path img_path(img_file);
  if (!std::filesystem::exists(img_path)) {
    std::cout << "Cannot open '" << img_file << "'\n";
    return 0;
  }
  return std::filesystem::file_size(img_path);
}
inline void load_img(char *mem_, const char *image) {
  if (image == nullptr) {
    std::cout << "No image is given. Use the default built-in image.\n";
    return;
  }
  long image_size;
  std::string img_file(image);
  std::filesystem::path img_path(img_file);
  if (!std::filesystem::exists(img_path)) {
    std::cout << "Cannot open '" << img_file << "'\n";
    return;
  }
  image_size = std::filesystem::file_size(img_path);
  std::ifstream file(image, std::ios::binary);

  file.read(mem_, image_size);
}
} // namespace Utils
