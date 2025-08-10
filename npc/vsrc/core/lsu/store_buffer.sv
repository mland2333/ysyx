module ysyx_24110006_STORE_BUFFER(
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    input lsu::rq_store_t i_rq,
    input store_retire,
    if_load_check.in check,
    output lsu::rq_store_t o_rq,
    input store_finish
);
  lsu::rq_store_t buffer;
  always_ff@(posedge i_clock)begin
    if(i_reset || (i_flush && o_vr.ready && !o_vr.valid)) i_vr.ready <= 1;
    else if(i_vr.valid && i_vr.ready && !i_flush) i_vr.ready <= 0;
    else if(!i_vr.ready && store_finish) i_vr.ready <= 1;
  end
  always_ff@(posedge i_clock)begin
    if(i_vr.valid && i_vr.ready && !i_flush)
      buffer <= i_rq;
  end
  always_ff@(posedge i_clock)begin
    if(i_reset) o_vr.valid <= 0;
    else if(store_retire) o_vr.valid <= 1;
    else if(o_vr.valid && o_vr.ready) o_vr.valid <= 0;
  end
  assign o_rq = buffer;
  assign check.hit = check.addr == buffer.addr && !i_vr.ready;
  assign check.data = buffer.wdata;
endmodule
