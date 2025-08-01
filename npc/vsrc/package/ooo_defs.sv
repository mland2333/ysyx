`include "common_config.sv"
package ooo;
  typedef struct packed {
    logic [6:0]  op;
    logic [2:0]  func;
    logic [31:0] pc;
    logic [31:0] imm;
  } basic_info_t;
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
    logic [1:0] need_rs;
    logic mem_wen;
    logic is_lsu;
  } idu2rename_t;
  typedef struct packed {
    basic_info_t basic_inst_info;
    pipe::reg_rinfo_t reg_rinfo;
    logic [`REG_NUM_INDEX-1:0] prd;
    logic [4:0] vrd;
    logic mem_wen;
    logic reg_wen;
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic [1:0] need_rs;
    logic [1:0] rs_valid;
    logic quit;
    logic is_lsu;
  } dispatch_info_t;
  typedef struct packed {
    logic flush_retire;
    logic retire;
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic [4:0] vrd;
    logic [`REG_NUM_INDEX-1:0] prd;
  } retire_info_t;
  typedef struct packed {
    basic_info_t basic_inst_info;
    pipe::reg_rinfo_t reg_rinfo;
    logic [1:0] need_rs;
    logic [1:0] rs_valid;
    logic ren_wen;
    logic mem_wen;
  } dispatch_inst_t;
  typedef struct packed {logic branch, beq, bne, blt, bge, jump;} branch_info_t;
  typedef struct packed {
    rob::wb_index rob_index;
    alu::op_t alu_op;
    logic [31:0] upc;
    logic [31:0] imm;
    logic zero;
    branch_info_t branch_info;
  } exu_info_t;
  typedef struct packed {
    basic_info_t data;
    rob::wb_index rob_index;
  } issue_int_t;
  typedef struct packed {
    logic wen;
    logic [31:0] imm;
    logic [2:0] func;
  } agu_info_t;
  typedef struct packed {
    agu_info_t agu_info;
    rob::wb_index rob_index;
  } issue_lsu_t;
  typedef struct packed{
    rob::wb_index rob_index;
    logic wen;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [2:0] read_t;
    logic [3:0] wmask;
  }lsu_info_t;
endpackage
