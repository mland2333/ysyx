interface if_rq_pht #(
    INDEX = 4
) ();
  logic [INDEX-1:0] index;
  logic pred_taken;
  modport in(input index, output pred_taken);
  modport out(output index, input pred_taken);
endinterface
