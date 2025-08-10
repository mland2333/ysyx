interface if_icache_rq ();
  logic        rq;
  logic        ready;
  logic [31:0] addr;
  logic        flush;

  logic [31:0] rdata;
  logic        cache_ready;
  logic        valid;
  logic [31:0] pc;

  modport master(output rq, ready, addr, flush, input rdata, cache_ready, valid, pc);

  modport slave(input rq, ready, addr, flush, output rdata, cache_ready, valid, pc);
endinterface
