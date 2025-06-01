`include "alu_config"
package alu;
  typedef struct packed{
    logic [31:0] a;
    logic [31:0] b;
    logic sub;
    logic sign;
    logic [`ALU_TYPE - 1:0] alu_t;
  } op_t;
  typedef struct packed{
    logic [31:0] r;
    logic [31:0] add_r;
    logic cmp;
  }result_t;

endpackage
