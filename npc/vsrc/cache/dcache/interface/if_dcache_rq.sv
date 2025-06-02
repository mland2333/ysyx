`include "common_config.sv"
interface if_dcache_rq ();
  // dcache -> cache2axi signals
  logic rq;
  logic wen;
  logic ready;
  logic [31:0] addr;
  logic [`DCACHE_LINE_WIDTH-1:0] w_cache_line;
  // cache2axi -> dcache signals
  logic [`DCACHE_LINE_WIDTH-1:0] r_cache_line;
  logic ack;
  logic valid;

  modport master(output rq, wen, ready, addr, w_cache_line, input r_cache_line, ack, valid);
  modport slave(input rq, wen, ready, addr, w_cache_line, output r_cache_line, ack, valid);

endinterface

