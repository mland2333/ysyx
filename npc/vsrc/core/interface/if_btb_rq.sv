interface if_rq_btb();
  logic [31:0] pc;
  logic hit, ret, call;
  logic [31:0] upc;
  modport out(output pc, input hit, upc, ret, call);
  modport in(input pc, output hit, upc, ret, call);
endinterface
