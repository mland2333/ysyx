#include <proc.h>
#include <elf.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif
extern size_t get_ramdisk_size();
extern size_t ramdisk_read(void*, size_t, size_t);
static uintptr_t loader(PCB *pcb, const char *filename) {
  /* TODO(); */
  /* size_t ramdisk_size = get_ramdisk_size(); */
  Elf_Ehdr header;
  ramdisk_read((void*)&header, 0, sizeof(Elf_Ehdr));
  assert(*(uint32_t *)header.e_ident == 0x464c457f);
  uintptr_t entry = header.e_entry;
  size_t phoff = header.e_phoff;
  size_t phnum = header.e_phnum;
  Elf_Phdr phdr;
  for (int i = 0; i < phnum; i++) {
    uintptr_t phdr_addr = phoff + i * (sizeof(Elf_Phdr));
    ramdisk_read((void*)&phdr, phdr_addr, sizeof(Elf_Phdr));
    if (phdr.p_type == PT_LOAD) {
      uintptr_t vaddr = phdr.p_vaddr;
      size_t offset = phdr.p_offset;
      size_t len = phdr.p_memsz;
      ramdisk_read((void*)vaddr, offset, len);
    }
  }
  
  return entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

