ENTRY(_start)
MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 16M
}
SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(flash);
  .text : 
  ALIGN(8)
  {
    *(entry)
    *(.text*)
  } > flash AT> flash

  . = ALIGN(8);
  etext = .;
  _etext = .;

  .rodata : 
  ALIGN(4)
  {
    . = ALIGN(8);
    *(.rodata*)
    . = ALIGN(8);
  } > flash AT> flash

  _data_load_start = .;
  .data : 
  ALIGN(8)
  {
    . = ALIGN(8);
    _data_start = .;
    *(.data*)
    *(.sdata*)
    _data_end = .;
    . = ALIGN(8);
  } > sram AT> flash
  /* _data_load_end = LOADADDR(.data) + SIZEOF(.data); */
  /* _data_load_end = .; */
  edata = .;
  _data = .;

  .bss : {
    . = ALIGN(8);
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
  } > sram AT> flash

  . = ALIGN(8);
  _stack_top = _bss_end;
  . = _stack_top + 0x1000;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(8);
}
