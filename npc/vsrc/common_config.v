
`ifdef CONFIG_AREA_OPT
  `define PC_LOW 2
  `define PC_FULL(pc) {pc, 2'b0}
`else
  `define PC_LOW 0
  `define PC_FULL(pc) pc
`endif

`define PC_WIDTH 31:`PC_LOW
