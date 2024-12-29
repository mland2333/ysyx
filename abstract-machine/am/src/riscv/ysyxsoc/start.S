.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, _stack_pointer
  la a0, _boot_load_start
  la a1, _boot_start
  la a2, _boot_end
fsbl:
  bgeu a1, a2, ssbl
  lw a3, 0(a0)
  sw a3, 0(a1)
  addi a0, a0, 0x4
  addi a1, a1, 0x4
  j fsbl
ssbl:
  call _bootloader
  call _trm_init
