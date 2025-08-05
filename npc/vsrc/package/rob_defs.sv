`include "common_config.sv"
package rob;
  typedef struct packed {
    logic [31:0] pc;
    logic reg_wen;
    logic [`REG_NUM_INDEX-1:0] prd;
    logic [4:0] vrd;
    logic has_old_map;
    logic [`REG_NUM_INDEX-1:0] old_index;
    logic quit;
  } inst_info_t;
  typedef struct packed {logic difftest_skip;} sim_t;
  typedef struct packed {
    logic [31:0] result;
    logic [31:0] upc;
    logic flush;
`ifdef CONFIG_SIM
    sim_t sim;
`endif
  } result_t;
  typedef struct packed {
    inst_info_t inst_info;
    result_t result;
    logic valid;
    logic type_store;
  } rob_t;
  typedef logic [`ROB_NUM_INDEX-1:0] wb_index;
  typedef struct packed {
    logic valid;
    wb_index index;
    result_t result;
  } commit_info_t;
  typedef struct packed{
    logic valid;
    wb_index index;
  } store_commit_t;
endpackage
