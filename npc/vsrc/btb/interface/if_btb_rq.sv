interface if_btb_rq ();
  logic [31:0] pc;
  logic [31:0] upc;
  logic update;
  logic hit;
  logic [31:0] btb_pc;

  modport master(input pc, upc, update, output hit, btb_pc);
  modport slave(output pc, upc, update, input hit, btb_pc);

endinterface
