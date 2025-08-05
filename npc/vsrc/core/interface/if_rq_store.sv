interface if_rq_store ();
  logic rq;
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [3:0] wmask;
  logic ready;
  logic valid;
  logic ack;
  modport in(input rq, addr, wdata, wmask, ready, output valid, ack);
  modport out(output rq, addr, wdata, wmask, ready, input valid, ack);
endinterface
