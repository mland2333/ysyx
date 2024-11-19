#include <common.h>
#ifdef CONFIG_FTRACE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <elf.h>
#include <ftrace.h>

extern Ftrace* ftrace;
Ftrace* init_ftrace(char* filename){
  FILE* file = fopen(filename, "r");
  Elf32_Ehdr elf_header;
  Elf32_Sym* func_table = NULL;
  int func_num = 0;
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
    return 0;
  }
  char* string_table = (char *)malloc(strtab_hdr->sh_size);
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
  Ftrace* m_ftrace = (Ftrace*) malloc(sizeof(Ftrace));
  m_ftrace->func_num = func_num;
  m_ftrace->func_table = func_table;
  m_ftrace->string_table = string_table;
  return m_ftrace;
}

int call_func(uint32_t ptr)
{
  for(int i = 0; i < ftrace->func_num; i++)
  {
    if(ptr == ftrace->func_table[i].st_value)
      return ftrace->func_table[i].st_name;
  }
  return -1;
}

int ret_func(uint32_t ptr)
{
  for(int i = 0; i < ftrace->func_num; i++)
  {
    if(ptr >= ftrace->func_table[i].st_value && ptr < ftrace->func_table[i].st_value + ftrace->func_table[i].st_size)
      return ftrace->func_table[i].st_name;
  }
  return -1;
}

#endif
