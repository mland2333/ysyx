package bp;
  typedef struct packed{
    logic pred_taken;
    logic [31:0] pred_pc;
  }info_t;
  typedef struct packed{
    logic valid;
    logic pred_taken, taken, jal, jalr, pred_err, branch;
    logic [31:0] pc, upc;
    logic call, ret;
  }result_t;
  typedef struct packed{
    logic valid;
    logic [31:0] pc;
    logic taken;
  }update_bht_t;
  typedef struct packed{
    logic valid;
    logic [4:0] index;
    logic taken;
  }update_pht_t;
  typedef struct packed{
    logic valid;
    logic [31:0] pc;
    logic [31:0] upc;
  }update_btb_t;
  typedef struct packed{
    info_t d1, d2;
  }info_group_t;


endpackage
