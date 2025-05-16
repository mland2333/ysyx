interface if_dcache_axi();
  // dcache -> cache2axi signals
  logic rq;
  logic wen;
  logic [31:0] addr;
  logic [31:0] wdata;
  logic wdata_valid;
  logic wlast;
  logic rdata_ready;
  
  // cache2axi -> dcache signals
  logic rq_ack;
  logic [31:0] rdata;
  logic rdata_valid;
  logic fin_r;
  logic wdata_ready;
  logic fin_w;
  
  // Master port (DCACHE side)
  modport master(
    output rq, wen, addr, wdata, wdata_valid, wlast, rdata_ready,
    input rq_ack, rdata, rdata_valid, fin_r, wdata_ready, fin_w
  );
  
  // Slave port (CACHE2AXI side)
  modport slave(
    input rq, wen, addr, wdata, wdata_valid, wlast, rdata_ready,
    output rq_ack, rdata, rdata_valid, fin_r, wdata_ready, fin_w
  );
endinterface 
