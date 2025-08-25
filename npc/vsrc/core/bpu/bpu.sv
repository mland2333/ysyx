module BPU #(
    BHT_NUM   = 128,
    WIDTH = 5,
    PHT_NUM = 1024
) (
    input i_clock,
    i_reset,
    input bp::result_t result,
    if_rq_bp.in i_rq
`ifdef CONFIG_SIM
    ,output perf::bpu_t perf_bpu
`endif
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
`ifdef CONFIG_SIM
  logic [perf::PERF_BPU_COUNT-1:0] perf_trigger;
  assign perf_trigger[perf::branch] = result.valid && result.branch;
  assign perf_trigger[perf::jal] = result.valid && result.jal;
  always_ff@(posedge i_clock)begin
    for(int i = 0; i<perf::PERF_BPU_COUNT; i++)begin
      if(i_reset) perf_bpu.d[i] <= 0;
      else if(perf_trigger[i]) begin
        if(result.taken && result.pred_taken) perf_bpu.d[i].pred_right <= perf_bpu.d[i].pred_right + 1;
        else if(result.taken && !result.pred_taken) perf_bpu.d[i].unpred_wrong <= perf_bpu.d[i].unpred_wrong + 1;
        else if(!result.taken && result.pred_taken) perf_bpu.d[i].pred_wrong <= perf_bpu.d[i].pred_wrong + 1;
        else if(!result.taken && !result.pred_taken) perf_bpu.d[i].unpred_right <= perf_bpu.d[i].unpred_right + 1;
      end
    end
  end
  logic [31:0] _pc;
  always_ff@(posedge i_clock)begin
    if(i_reset) _pc <= 0;
    else if(result.valid && (result.branch || result.jal))
      _pc <= result.pc;
  end
  perf::type_t branch_type[perf::PERF_BPU_COUNT];
  always_comb begin
    for(int i=0; i<perf::PERF_BPU_COUNT; i++)
      branch_type[i] = perf::type_t'(i);
  end
  int fd;
  perf::BpHistory history;
  initial begin
    fd = $fopen("state.logic", "w");
    history = new();
  end
  /* always_ff@(posedge i_clock)begin */
  /*   for(int i=0; i<perf::PERF_BPU_COUNT; i++)begin */
  /*     if(perf_trigger[i])begin */
  /*       if(result.pc != _pc) begin */
  /*         $fwrite(fd, "0x%x, %s, %b, %b\n", result.pc, branch_type[i].name(), result.pred_taken, result.taken); */
  /*       end */
  /*       else begin */
  /*         $fwrite(fd, "%s, %s, %b, %b\n", "          ", branch_type[i].name(), result.pred_taken, result.taken); */
  /*       end */
  /*     end */
  /*   end */
  /* end */

  always_ff@(posedge i_clock)begin
    if(perf_trigger[perf::branch])
      history.update(result.pc, result.pred_taken, result.taken);
  end
  final begin
    $fclose(fd);
    history.print();
  end
  
`endif
endmodule
