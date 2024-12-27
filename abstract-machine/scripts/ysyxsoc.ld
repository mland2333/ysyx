ENTRY(_start)
MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}
SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(mrom);
  .text : {
    *(entry)
    *(.text*)
  } > mrom AT> mrom
  . = ALIGN(8);
  etext = .;
  _etext = .;
  .rodata : {
    . = ALIGN(8);
    *(.rodata*)
  } > mrom AT> mrom
  . = ALIGN(8);
  _data_load_start = .;
  .data : {
    . = ALIGN(8);
    _data_start = .;
    *(.data)
    . = ALIGN(8);
    _data_end = .;
  } > sram AT> mrom
  . = ALIGN(8);
  edata = .;
  _data = .;
  .bss : {
    . = ALIGN(8);
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
  } > sram AT> mrom
  _stack_top = _bss_end;
  . = _stack_top + 0x1000;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(8);
}
