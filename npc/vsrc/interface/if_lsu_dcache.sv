interface if_lsu_dcache ();
  // lsu -> dcache signals
  logic        rq;  // Request signal
  logic        ren;
  logic        wen;  // Write enable
  logic        ready;
  logic [31:0] addr;  // Address
  logic [31:0] wdata;  // Write data
  logic [ 3:0] wmask;  // Write mask

  // dcache -> lsu signals
  logic [31:0] rdata;  // Read data
  logic        ack;  // Acknowledge signal
  logic        valid;  // Ready signal

  // Master port (LSU side)
  modport master(output rq, ren, wen, ready, addr, wdata, wmask, input rdata, ack, valid);

  // Slave port (DCACHE side)
  modport slave(input rq, ren, wen, ready, addr, wdata, wmask, output rdata, ack, valid);
endinterface

