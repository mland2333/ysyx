module ysyx_24110006_DCACHE_NEW(
  input i_clock,
  input i_reset,
  //lsu <--> cache
  if_lsu_dcache.slave i_lsu,
  //axi <--> mem
  if_axi.master o_axi
);

  // Instantiate the interface between MDCACHE and CACHE2AXI
  if_dcache_axi dcache_axi_if();

  // Instantiate MDCACHE
  ysyx_24110006_MDCACHE mdcache(
    .i_clock(i_clock),
    .i_reset(i_reset),
    .i_lsu(i_lsu),
    .o_axi(dcache_axi_if.master)
  );

  // Instantiate CACHE2AXI
  ysyx_24110006_CACHE2AXI cache2axi(
    .i_clock(i_clock),
    .i_reset(i_reset),
    .i_dcache(dcache_axi_if.slave),
    .o_axi(o_axi)
  );

endmodule 