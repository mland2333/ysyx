`include "alu_config.sv"
`include "common_config.sv"
package pipe;
  typedef struct packed {
    logic [31:0] inst;
    logic [31:0] imm;
    logic [31:0] pc;
    logic exception;
    logic [3:0] mcause;
  } ifu2idu_t;
  typedef struct packed {
    logic [6:0] op;
    logic [2:0] func;
    logic [1:0] csr_t;
    logic [11:0] csr;
    logic [`REG_NUM_INDEX-1:0] reg_rd;
    logic [31:0] imm;
    logic [31:0] pc;
    logic exception;
    logic [3:0] mcause;
    logic quit;
  } idu2exu_t;
  typedef struct packed {
    logic [6:0]  op;
    logic [2:0]  func;
    logic [31:0] imm;
    logic [31:0] pc;
  } idu2aluop_t;

  typedef struct packed {
    logic [`REG_NUM_INDEX-1:0] rs1;
    logic [`REG_NUM_INDEX-1:0] rs2;
`ifdef CONFIG_RENAME
    logic [1:0] rs_zero;
`endif
  } reg_rinfo_t;
  typedef struct packed {
    logic [31:0] r1;
    logic [31:0] r2;
  } reg_rdata_t;
  typedef struct packed {
    logic [`REG_NUM_INDEX-1:0] rd;
    logic [31:0] wdata;
    logic wen;
  } reg_winfo_t;
  typedef struct packed {
    logic [11:0] csr_r;
    logic mret;
  } csr_rinfo_t;
  typedef struct packed {
    logic [31:0] r1;
    logic [31:0] upc;
  } csr_rdata_t;
  typedef struct packed {
    logic [11:0] csr_w;
    logic [1:0] csr_t;
    logic [31:0] wdata;
  } csr_winfo_t;
  typedef struct packed {
    logic [31:0] pc;
    logic exception;
    logic [3:0] mcause;
  } csr_einfo_t;
  typedef struct packed {
    logic [31:0] result;
    logic reg_wen;
    logic jump;
    logic [`BRANCH_MID] branch_mid;
    logic [31:0] upc;
    logic [1:0] csr_t;
    logic [11:0] csr;
    logic [`REG_NUM_INDEX-1:0] reg_rd;
    logic [31:0] pc;
    logic exception;
    logic [3:0] mcause;
    logic [31:0] csr_wdata;
    logic fencei;
    logic quit;
`ifdef CONFIG_RENAME
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic [4:0] vrd;
`endif
  } exu2bru_t;
  typedef struct packed {
    logic ren;
    logic wen;
    logic reg_wen;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [3:0] wmask;
    logic [2:0] read_t;
    logic [`REG_NUM_INDEX-1:0] reg_rd;
    logic [31:0] pc;
    logic exception;
    logic [3:0] mcause;
`ifdef CONFIG_RENAME
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic [4:0] vrd;
`endif
  } exu2lsu_t;
  typedef struct packed {
    logic [31:0] result;
    logic reg_wen;
    logic [`REG_NUM_INDEX-1:0] reg_rd;
    logic [31:0] pc;
`ifdef CONFIG_RENAME
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic is_flush;
    logic [4:0] vrd;
`endif
  } wbu_t;
  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] inst;
  }sim_t;
endpackage
