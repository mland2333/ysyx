interface if_rq_bp ();
  logic [31:0] pc;
  logic pred_taken;
  logic [31:0] upc;
  modport out(output pc, input pred_taken, upc);
  modport in(input pc, output pred_taken, upc);
endinterface
