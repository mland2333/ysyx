module ysyx_24110006_IBUFFER #(
    parameter INST_BUFFER_WIDTH = 64
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input i_fencei,
    input pipe::ifu2idu_t from_ifu,
    output pipe::ifu2idu_single_t to_idu,
    if_pipeline_vr i_vr,
    if_pipeline_vr o_vr
);
  if_rq_fifo #(.WIDTH($bits(pipe::ifu2idu_single_t))) rq1();
  if_rq_fifo #(.WIDTH($bits(pipe::ifu2idu_single_t))) rq2();
  logic empty, full, almost_full;
  assign i_vr.ready = !full && !almost_full;
  assign o_vr.valid = !empty;
  logic [1:0] pop_valid, push_valid;
  logic pop, push;
  assign pop = o_vr.valid && o_vr.ready;
  assign push = i_vr.valid && i_vr.ready;
  assign rq1.push = push;
  assign rq1.pop = pop;
  assign rq2.push = push && from_ifu.d2.inst_valid;
  assign rq2.pop = 0;
  assign rq1.push_data = from_ifu.d1;
  assign rq2.push_data = from_ifu.d2;
  assign to_idu = rq1.pop_data;
  DOUBLE_PROT_FIFO #(
      .WIDTH($bits(pipe::ifu2idu_single_t)),
      .NUM  (INST_BUFFER_WIDTH)
  ) ibuffer (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(i_flush),
      .rq1(rq1),
      .rq2(rq2),
      .empty(empty),
      .almost_empty(),
      .full(full),
      .almost_full(almost_full)
  );
endmodule
