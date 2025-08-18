module ysyx_24110006_IBUFFER #(
    parameter INST_BUFFER_WIDTH = 64
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input i_fencei,
    input pipe::ifu2idu_t from_ifu,
    output pipe::ifu2idu_t to_idu,
    if_pipeline_vr i_vr,
    if_pipeline_vr o_vr
);
  if_rq_fifo #(.WIDTH($bits(pipe::ifu2idu_single_t))) rq1();
  if_rq_fifo #(.WIDTH($bits(pipe::ifu2idu_single_t))) rq2();
  logic empty, full, almost_full, almost_empty;
  assign i_vr.ready = !full && !almost_full;
  assign o_vr.valid = !empty;
  logic [1:0] pop_valid, push_valid;
  logic pop, push;
  logic have_two_inst, two_store, two_load;
  assign have_two_inst = !empty && !almost_empty;
  assign two_store = to_idu.d1.inst[6:0] == 7'b0100011 && to_idu.d2.inst[6:0] == 7'b0100011;
  assign two_load = to_idu.d1.inst[6:0] == 7'b0000011 && to_idu.d2.inst[6:0] == 7'b0000011;
  assign pop = o_vr.valid && o_vr.ready;
  assign push = i_vr.valid && i_vr.ready;
  assign rq1.push = push;
  assign rq1.pop = pop;
  assign rq2.push = push && from_ifu.inst_valid[1];
  assign rq2.pop = pop && have_two_inst && !two_load && !two_store;
  assign rq1.push_data = from_ifu.d1;
  assign rq2.push_data = from_ifu.d2;
  assign to_idu.d1 = rq1.pop_data;
  assign to_idu.d2 = rq2.pop_data;
  assign to_idu.inst_valid = {rq2.pop, rq1.pop};
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
      .almost_empty(almost_empty),
      .full(full),
      .almost_full(almost_full)
  );
endmodule
