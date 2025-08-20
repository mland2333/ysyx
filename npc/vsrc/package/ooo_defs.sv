`include "common_config.sv"
package ooo;
  typedef struct packed {
    logic [6:0]  op;
    logic [2:0]  func;
    logic [31:0] pc;
    logic [31:0] imm;
  } basic_info_t;
  typedef struct packed {
    rf::vreg [1:0] vrs;
    rf::vreg vrd;
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
    bp::info_t bp_info;
  } idu2rename_single_t;
  typedef struct packed {
    idu2rename_single_t [1:0] d;
    logic [1:0] inst_valid;
  }idu2rename_t;
  typedef struct packed {
    basic_info_t basic_inst_info;
    rf::rinfo_t reg_rinfo;
    rf::preg prd;
    rf::vreg vrd;
    logic mem_wen;
    logic reg_wen;
    logic has_old_map;
    rf::preg old_index;
    logic [1:0] need_rs;
    logic [1:0] rs_valid;
    logic quit;
    logic is_lsu;
    bp::info_t bp_info;
  } dispatch_single_t;
  typedef struct packed {
    dispatch_single_t [1:0] d;
    logic [1:0] inst_valid;
  } dispatch_info_t;
  typedef struct packed {
    logic flush;
    logic valid;
    logic has_old_map;
    rf::preg old_index;
    rf::vreg vrd;
    rf::preg prd;
  } retire_info_t;
  typedef struct packed {
    logic valid;
    rf::vreg vrd;
    rf::preg prd;
  } commit_update_t;
  typedef struct packed {
    basic_info_t basic_inst_info;
    rf::rinfo_t reg_rinfo;
    logic [1:0] need_rs;
    logic [1:0] rs_valid;
    logic reg_wen;
    logic mem_wen;
    rf::preg rd;
    rf::vreg vrd;
    bp::info_t bp_info;
  } dispatch_inst_t;
  typedef struct packed {logic branch, beq, bne, blt, bge, branch_back, jal, jalr, ret;} branch_info_t;
  typedef struct packed {
    rob::wb_index rob_index;
    alu::op_t alu_op;
    logic [31:0] upc;
    logic [31:0] imm;
    logic zero;
    logic reg_wen;
    branch_info_t branch_info;
    rf::preg rd;
    rf::vreg vrd;
    bp::info_t bp_info;
  } exu_info_t;
  typedef struct packed {
    basic_info_t data;
    rob::wb_index rob_index;
    logic reg_wen;
    rf::preg rd;
    rf::vreg vrd;
    bp::info_t bp_info;
  } issue_int_t;
  typedef struct packed {
    logic wen;
    logic [31:0] imm;
    logic [2:0] func;
  } agu_info_t;
  typedef struct packed {
    agu_info_t agu_info;
    rob::wb_index rob_index;
    rf::preg rd;
    rf::vreg vrd;
    rob::wb_index store_index;
  } issue_lsu_t;
  typedef struct packed {
    rob::wb_index rob_index;
    logic wen;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [2:0] read_t;
    logic [3:0] wmask;
    rf::preg rd;
    rf::vreg vrd;
  } lsu_info_t;

endpackage
