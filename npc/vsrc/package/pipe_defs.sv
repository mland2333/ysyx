`include "alu_config.sv"
`include "common_config.sv"
package pipe;
  typedef struct packed {
    logic [31:0] inst;
    logic [31:0] imm;
    logic [31:0] pc;
    logic exception;
    logic [3:0] mcause;
    bp::info_t bp_info;
  } ifu2idu_single_t;
  typedef struct packed {
    ifu2idu_single_t d1, d2;
    logic [1:0] inst_valid;
  } ifu2idu_t;
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
    logic [31:0] pc;
    logic [31:0] inst;
  }sim_t;
endpackage
