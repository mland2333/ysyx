interface if_rq_bp ();
  logic [31:0] pc;
  logic pred_taken;
  logic [31:0] upc;
  logic [1:0] inst_valid;
  modport out(output pc, input pred_taken, upc, inst_valid);
  modport in(input pc, output pred_taken, upc, inst_valid);
endinterface
