ENTRY(_start)
MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}
SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(flash);
  .text.start :
  ALIGN(8)
  {
    . = ALIGN(8);
    *(entry)
    . = ALIGN(8);
  }>flash AT> flash

  . = ALIGN(8);
  _boot_load_start = .;
  .text.bootloader :
  ALIGN(8)
  {
    _boot_start = .;
    . = ALIGN(8);
    *(bootloader)
    . = ALIGN(8);
    _boot_end = .;
  }>sram AT> flash
  . = LOADADDR(.text.bootloader) + SIZEOF(.text.bootloader);
  . = ALIGN(8);
  _text_load_start = .;
  .text : 
  ALIGN(8)
  {
    _text_start = .;
    EXCLUDE_FILE (start.* bootloader.*) *(.text*)
    . = ALIGN(8);
  } > psram AT> flash

  . = ALIGN(8);
  etext = .;
  _etext = .;

  .rodata : 
  ALIGN(8)
  {
    . = ALIGN(8);
    *(.rodata*)
    . = ALIGN(8);
  } > psram AT> flash
  
  .data.extra : 
  ALIGN(8)
  {
    /* section information for finsh shell */
    . = ALIGN(8);
    __fsymtab_start = .;
    KEEP(*(FSymTab))
    __fsymtab_end = .;
    . = ALIGN(8);
    __vsymtab_start = .;
    KEEP(*(VSymTab))
    __vsymtab_end = .;
    . = ALIGN(8);

    /* sec
     * tion information for initial. */
    . = ALIGN(8);
    __rt_init_start = .;
    KEEP(*(SORT(.rti_fn*)))
    __rt_init_end = .;
    . = ALIGN(8);

    __rt_utest_tc_tab_start = .;
    KEEP(*(UtestTcTab))
    __rt_utest_tc_tab_end = .;

    . = ALIGN(8);
    __am_apps_data_start = .;
    *(__am_apps.data*)
    *(__am_apps.sdata*)
    __am_apps_data_end = .;
    . = ALIGN(8);
  } >psram AT> flash

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
  } > psram AT> flash
  /* _data_load_end = LOADADDR(.data) + SIZEOF(.data); */
  /* _data_load_end = .; */
  edata = .;
  _data = .;
  .bss.extra : {
    . = ALIGN(8);
    __am_apps_bss_start = .;
    *(__am_apps.bss*)
    *(__am_apps.sbss*)
    *(__am_apps.scommon*)
    __am_apps_bss_end = .;
    . = ALIGN(8);
  } >psram AT> flash

  .bss : {
    . = ALIGN(8);
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon*)
    _bss_end = .;
  } > psram AT> flash
  . = _bss_end;
  . = ALIGN(8);
  _heap_start = .;
  _stack_top = 0x80400000;
  . = 0x0f002000;
  _stack_pointer = .;
  end = .;
  _end = .;
}
