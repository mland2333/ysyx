.section bootloader, "ax"
.globl _bootloader
.type _bootloader, @function

_bootloader:
  la a0, _text_load_start
  la a1, _text_start
  la a2, _bss_end
_loader:
  bgeu a1, a2, _ret
  lw a3, 0(a0)
  sw a3, 0(a1)
  addi a0, a0, 0x4
  addi a1, a1, 0x4
  j _loader
_ret:
  ret
