interface if_lsu_adapter ();
  // lsu -> adapter signals
  logic rq;
  logic ren;
  logic wen;
  logic ready;
  logic [2:0] read_t;
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [3:0] wmask;
  logic fencei;

  // adapter -> lsu signals
  logic [31:0] rdata;
  logic ack;
  logic valid;
  logic fencei_fin;

  // Master port (LSU side)
  modport master(output wen, ren, rq, read_t, addr, wdata, wmask, ready, fencei, input rdata, valid, ack, fencei_fin);

  // Slave port (ADAPTER side)
  modport slave(input wen, ren, rq, read_t, addr, wdata, wmask, ready, fencei, output rdata, valid, ack, fencei_fin);
endinterface

