interface if_icache_rq ();
  logic             rq;
  logic             ready;
  logic      [31:0] addr;
  logic             flush;
  bp::info_t        bp_info_in;

  logic      [31:0] rdata;
  logic             cache_ready;
  logic             valid;
  logic      [31:0] pc;
  bp::info_t        bp_info_out;

  modport master(
      output rq, ready, addr, flush, bp_info_in,
      input rdata, cache_ready, valid, pc, bp_info_out
  );

  modport slave(
      input rq, ready, addr, flush, bp_info_in,
      output rdata, cache_ready, valid, pc, bp_info_out
  );
endinterface
