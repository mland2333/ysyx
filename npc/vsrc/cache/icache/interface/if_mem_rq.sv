`include "icache_config.sv"
interface if_mem_rq ();
  logic rq;
  logic ready;
  logic [31:0] addr;
  logic [127:0] r_cache_line;
  logic ack;
  logic valid;

  modport master(output rq, ready, addr, input r_cache_line, ack, valid);
  modport slave(input rq, ready, addr, output r_cache_line, ack, valid);

endinterface
