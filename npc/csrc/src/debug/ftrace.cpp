#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <debug/ftrace.h>

void Ftrace::ftrace_file(const char* image){
  filename = image;
  size_t pos = filename.rfind(".bin");
  if (pos != std::string::npos) {
    filename.replace(pos, 4, ".elf");
  }
}
Ftrace::Ftrace(const char* image){
  ftrace_file(image);
  int name_size = 0;
  FILE* file = fopen(filename.c_str(), "r");
  Elf32_Ehdr elf_header;
  fread(&elf_header, sizeof(Elf32_Ehdr), 1, file);
  fseek(file, elf_header.e_shoff, SEEK_SET);
  Elf32_Shdr* section_headers =
      (Elf32_Shdr *)malloc(elf_header.e_shentsize * elf_header.e_shnum);
  fread(section_headers, elf_header.e_shentsize, elf_header.e_shnum, file);
  Elf32_Shdr *symtab_hdr = NULL;
  Elf32_Shdr *strtab_hdr = NULL;
  for (int i = 0; i < elf_header.e_shnum; i++) {
    if (section_headers[i].sh_type == SHT_SYMTAB) {
      symtab_hdr = &section_headers[i];
    } else if (section_headers[i].sh_type == SHT_STRTAB) {
      strtab_hdr = &section_headers[i];
      break;
    }
  }
  if (symtab_hdr == NULL || strtab_hdr == NULL) {
    printf("未找到符号表或字符串表\n");
    return;
  }
  string_table = (char *)malloc(strtab_hdr->sh_size);
  Elf32_Sym* symbol_table = (Elf32_Sym *)malloc(symtab_hdr->sh_size);
  fseek(file, strtab_hdr->sh_offset, SEEK_SET);
  fread(string_table, 1, strtab_hdr->sh_size, file);
  fseek(file, symtab_hdr->sh_offset, SEEK_SET);
  fread(symbol_table, symtab_hdr->sh_size, 1, file);
  func_table = (Elf32_Sym *)malloc(symtab_hdr->sh_size);
  for (int i = 0; i < (symtab_hdr->sh_size / sizeof(Elf32_Sym)); i++) {
    if (ELF32_ST_TYPE(symbol_table[i].st_info) == STT_FUNC) {
      memcpy(&func_table[func_num++], &symbol_table[i], sizeof(Elf32_Sym));
    }
  }
  free(section_headers);
  free(symbol_table);
  fclose(file);
}

int Ftrace::func_head(uint32_t ptr){
  for(int i = 0; i < func_num; i++)
  {
    if(ptr == func_table[i].st_value)
      return func_table[i].st_name;
  }
  return -1;
}

int Ftrace::func_body(uint32_t ptr){
  for(int i = 0; i < func_num; i++)
  {
    if(ptr >= func_table[i].st_value && ptr < func_table[i].st_value + func_table[i].st_size)
      return func_table[i].st_name;
  }
  return -1;
}

void Ftrace::trace(uint32_t pc, uint32_t upc, bool jump){
  int name;
  if (jump) {
    if ((name = func_head(upc)) != -1) {
      space_num++;
      printf("0x%x:", pc);
      for(int i = 0; i<space_num; i++)
        printf(" ");
      printf("call [%s@0x%x]\n", &string_table[name], upc);
    }
    else if ((name = func_body(upc)) != -1) {
      printf("0x%x:", pc);                                  
      for(int i = 0; i<space_num; i++)                         
        printf(" ");                                         
      space_num--;                                             
      printf("ret  [%s@0x%x]\n", &string_table[name], upc);
    }
  }
}

