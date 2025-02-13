#include <proc.h>
#include <elf.h>
#include <fs.h>
#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif
static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr header;
  int fd = fs_open(filename, 0, 0);
  assert(fd != -1);
  fs_lseek(fd, 0, 0);
  fs_read(fd, (void*)&header, sizeof(Elf_Ehdr));
  /* ramdisk_read((void*)&header, 0, sizeof(Elf_Ehdr)); */
  assert(*(uint32_t *)header.e_ident == 0x464c457f);
  uintptr_t entry = header.e_entry;
  size_t phoff = header.e_phoff;
  size_t phnum = header.e_phnum;
  Elf_Phdr phdr;
  for (int i = 0; i < phnum; i++) {
    uintptr_t phdr_addr = phoff + i * (sizeof(Elf_Phdr));
    fs_lseek(fd, phdr_addr, 0);
    fs_read(fd, (void*)&phdr, sizeof(Elf_Phdr));
    if (phdr.p_type == PT_LOAD) {
      uintptr_t vaddr = phdr.p_vaddr;
      size_t offset = phdr.p_offset;
      size_t len = phdr.p_memsz;
      fs_lseek(fd, offset, 0);
      fs_read(fd, (void*)vaddr, len);
    }
  }
  
  return entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

