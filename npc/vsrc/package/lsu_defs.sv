package lsu;

  typedef struct packed{
    logic [31:0] addr, wdata;
    logic [3:0] wmask;
  }rq_store_t;
  typedef struct packed{
    logic [31:0] addr;
    logic [2:0] read_t;
    rob::wb_index rob_index;
  }rq_load_t;



endpackage
