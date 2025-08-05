interface if_rq_load ();
  logic rq;
  logic [31:0] addr;
  logic [31:0] rdata;
  logic [2:0] read_t;
  logic ready;
  logic valid;
  logic ack;
  modport in(input rq, addr, read_t, ready, output rdata, valid, ack);
  modport out(output rq, addr, read_t, ready, input rdata, valid, ack);
endinterface
