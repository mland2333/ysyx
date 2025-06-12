`include "common_config.sv"
package ooo;
  typedef struct packed {
    logic [4:0] vrs1;
    logic [4:0] vrs2;
    logic [4:0] vrd;
    logic reg_wen;
    logic [6:0] op;
    logic [2:0] func;
    logic [1:0] csr_t;
    logic [31:0] pc;
    logic [31:0] imm;
    logic [11:0] csr;
    logic exception;
    logic [3:0] mcause;
    logic quit;
    logic mret;
  } idu2rename_t;
  typedef struct packed {
    logic [6:0] op;
    logic [2:0] func;
    logic [1:0] csr_t;
    logic [11:0] csr;
    logic [`REG_NUM_INDEX-1:0] reg_rd;
    logic [4:0] vrd;
    logic [31:0] imm;
    logic [31:0] pc;
    logic exception;
    logic [3:0] mcause;
    logic quit;
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic [1:0] rs_zero;
  } rename2exu_t;
  typedef struct packed{
    logic flush_retire;
    logic retire;
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic [4:0] vrd;
    logic [`REG_NUM_INDEX-1:0] prd;
  } retire_info_t;
endpackage
