interface if_rq_btb();
  logic [31:0] pc;
  logic hit1, hit2;
  logic [31:0] upc1, upc2;
  modport out(output pc, input hit1, hit2, upc1, upc2 );
  modport in(input pc, output hit1, hit2, upc1, upc2);
endinterface
