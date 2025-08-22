interface if_rq_btb ();
  logic [31:0] pc;
  logic hit;
  logic [31:0] upc;
  modport out(output pc, input hit, upc);
  modport in(input pc, output hit, upc);
endinterface
