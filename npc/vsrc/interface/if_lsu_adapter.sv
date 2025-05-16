interface if_lsu_adapter ();
  // lsu -> adapter signals
  logic rq;
  logic ren;
  logic wen;
  logic [2:0] read_t;
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [3:0] wmask;

  // adapter -> lsu signals
  logic [31:0] rdata;
  logic valid;

  // Master port (LSU side)
  modport master(output wen, ren, rq, read_t, addr, wdata, wmask, input rdata, valid);

  // Slave port (ADAPTER side)
  modport slave(input wen, ren, rq, read_t, addr, wdata, wmask, output rdata, valid);
endinterface

