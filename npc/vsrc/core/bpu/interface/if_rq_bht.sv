interface if_rq_bht #(
    INDEX = 4
) ();
  logic [31:0] pc;
  logic [INDEX-1:0] index;
  modport out(input index, output pc);
  modport in(output index, input pc);
endinterface
