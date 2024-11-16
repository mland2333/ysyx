#include <debug/disasm.h>
#include <capstone/capstone.h>
#include <iostream>
static csh handle;
void init_disasm(){
  cs_err err = cs_open(CS_ARCH_RISCV, CS_MODE_RISCV32, &handle);
  if (err != CS_ERR_OK) {
    std::cerr << "Failed to initialize Capstone!" << std::endl;
    return;
  }
}

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte) {
	cs_insn *insn;
  size_t count = cs_disasm(handle, code, nbyte, pc, 0, &insn);
  int ret = snprintf(str, size, "%s", insn->mnemonic);
  if (insn->op_str != nullptr) {
    snprintf(str + ret, size - ret, "\t%s", insn->op_str);
  }
  cs_free(insn, count);
}
