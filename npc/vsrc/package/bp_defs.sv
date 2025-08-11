package bp;
  typedef struct packed{
    logic pred_taken;
  }info_t;
  typedef struct packed{
    logic pred_taken, btb_update;
    logic [31:0] pc, upc;
  }result_t;
  typedef struct packed{
    logic valid;
    logic [31:0] pc, upc;
  }btb_update_t;


endpackage
