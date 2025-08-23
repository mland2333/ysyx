interface if_rq_btb ();
  logic [31:0] pc;
  logic hit;
  logic [31:0] upc;
  logic [1:0] inst_valid;
  logic pht_hit;
  modport out(output pc, pht_hit, input hit, upc, inst_valid);
  modport in(input pc, pht_hit, output hit, upc, inst_valid);
endinterface
