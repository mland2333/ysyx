interface if_lsu_dcache ();
  // lsu -> dcache signals
  logic        rq;  // Request signal
  logic        ren;
  logic        wen;  // Write enable
  logic        ready;
  logic [31:0] addr;  // Address
  logic [31:0] wdata;  // Write data
  logic [ 3:0] wmask;  // Write mask
  logic        flush;

  // dcache -> lsu signals
  logic [31:0] rdata;  // Read data
  logic        ack;  // Acknowledge signal
  logic        valid;  // Ready signal
  logic        flush_fin;

  // Master port (LSU side)
  modport master(output rq, ren, wen, ready, addr, wdata, wmask, flush, input rdata, ack, valid, flush_fin);

  // Slave port (DCACHE side)
  modport slave(input rq, ren, wen, ready, addr, wdata, wmask, flush, output rdata, ack, valid, flush_fin);
endinterface

