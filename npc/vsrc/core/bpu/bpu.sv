module BPU #(
    BHT_NUM   = 32,
    WIDTH = 5,
    PHT_NUM = 1024
) (
    input i_clock,
    i_reset,
    input bp::result_t result,
    if_rq_bp.in i_rq
);
  localparam PHT_INDEX = $clog2(PHT_NUM);
  if_rq_bht #(.INDEX(PHT_INDEX)) rq_bht ();
  if_rq_pht #(.INDEX(PHT_INDEX)) rq_pht ();
  if_rq_btb rq_btb ();
  bp::update_bht_t update_bht;
  bp::update_pht_t update_pht;
  bp::update_btb_t update_btb;
  assign update_bht.pc = result.pc;
  assign update_bht.taken = result.taken;
  assign update_bht.valid = result.valid && (result.branch || result.jal);
  assign rq_bht.pc = i_rq.pc;

  assign update_pht.taken = result.taken;
  assign update_pht.valid = result.valid && (result.branch || result.jal);
  assign rq_pht.index = rq_bht.index;

  assign update_btb.pc = result.pc;
  assign update_btb.upc = result.upc;
  assign update_btb.valid = result.valid && (result.branch || result.jal) && (!result.pred_taken && result.taken || result.pred_err);
  assign rq_btb.pc = i_rq.pc;
  assign rq_btb.pht_hit = rq_pht.pred_taken;

  assign i_rq.pred_taken = rq_pht.pred_taken && rq_btb.hit;
  assign i_rq.upc = rq_btb.upc;
  assign i_rq.inst_valid = rq_btb.inst_valid;
  BHT #(
      .NUM  (BHT_NUM),
      .WIDTH(WIDTH)
  ) mbht (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .update(update_bht),
      .update_index(update_pht.index),
      .i_rq(rq_bht)
  );

  PHT #(
      .NUM(PHT_NUM)
  ) mpht (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .update(update_pht),
      .i_rq(rq_pht)
  );
  BTB #(
      .NUM(BHT_NUM)
  ) mbtb (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .update(update_btb),
      .i_rq(rq_btb)
  );

endmodule
