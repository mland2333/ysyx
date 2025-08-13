`include "common_config.sv"
package lsu;

  typedef struct packed{
    logic [31:0] addr, wdata;
    logic [3:0] wmask;
    rob::wb_index rob_index;
  }rq_store_t;
  typedef struct packed{
    logic [31:0] addr;
    logic [2:0] read_t;
    rob::wb_index rob_index;
    rf::preg rd;
    logic [4:0] vrd;
    rob::wb_index store_index;
  }rq_load_t;
  typedef struct packed{
    logic valid;
    rob::wb_index store_index;
  }older_store_t;


endpackage
