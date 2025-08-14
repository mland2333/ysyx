interface if_icache_rq ();
  logic             rq;
  logic             ready;
  logic      [31:0] addr;
  logic             flush;
  bp::info_group_t  bp_info_in;

  logic      [31:0] rdata1, rdata2;
  logic             cache_ready;
  logic             valid;
  logic      [31:0] pc;
  bp::info_group_t  bp_info_out;

  modport master(
      output rq, ready, addr, flush, bp_info_in,
      input rdata1, rdata2, cache_ready, valid, pc, bp_info_out
  );

  modport slave(
      input rq, ready, addr, flush, bp_info_in,
      output rdata1, rdata2, cache_ready, valid, pc, bp_info_out
  );
endinterface
