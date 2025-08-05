module ysyx_24110006_STORE_UNIT (
    input i_clock,
    input i_reset,
    if_pipeline_vr.in i_vr,
    input lsu::rq_store_t i_rq,
    if_rq_store.out o_rq
);
  lsu::rq_store_t rq;
  always_ff @(posedge i_clock) begin
    if (i_reset) i_vr.ready <= 1;
    else if (i_vr.valid && i_vr.ready) i_vr.ready <= 0;
    else if (o_rq.valid && !i_vr.ready) i_vr.ready <= 1;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) o_rq.rq <= 0;
    else if (!o_rq.rq && i_vr.valid && i_vr.ready) o_rq.rq <= 1;
    else if (o_rq.rq && o_rq.ack) o_rq.rq <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_vr.valid && i_vr.ready) rq <= i_rq;
  end
  logic [ 3:0] wmask_aligned;
  logic [31:0] wdata_aligned;
  always_comb begin
    unique case (rq.addr[1:0])
      2'b00: begin
        wdata_aligned = rq.wdata;
        wmask_aligned = rq.wmask;
      end
      2'b01: begin
        wdata_aligned = {rq.wdata[23:0], rq.wdata[31:24]};
        wmask_aligned = {rq.wmask[2:0], 1'b0};
      end
      2'b10: begin
        wdata_aligned = {rq.wdata[15:0], rq.wdata[31:16]};
        wmask_aligned = {rq.wmask[1:0], 2'b0};
      end
      2'b11: begin
        wdata_aligned = {rq.wdata[7:0], rq.wdata[31:8]};
        wmask_aligned = {rq.wmask[0], 3'b0};
      end
    endcase
  end


  assign o_rq.addr  = rq.addr;
  assign o_rq.wdata = wdata_aligned;
  assign o_rq.wmask = wmask_aligned;
  assign o_rq.ready = 1;


endmodule
