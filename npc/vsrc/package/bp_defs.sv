package bp;
  typedef struct packed{
    logic pred_taken;
    logic [31:0] pred_pc;
  }info_t;
  typedef struct packed{
    logic pred_taken, btb_update;
    logic [31:0] pc, upc;
    logic call, ret;
  }result_t;
  typedef struct packed{
    logic valid;
    logic [31:0] pc, upc;
    logic call, ret;
  }btb_update_t;
  typedef struct packed{
    info_t d1, d2;
  }info_group_t;


endpackage
