module ysyx_24110006_IBUFFER #(
  parameter INST_BUFFER_WIDTH = 32
  )(
  input i_clock,
  input i_reset,
  input i_flush,
  input i_fencei,
  input pipe::ifu2idu_t from_ifu,
  output pipe::ifu2idu_t to_idu,
  if_pipeline_vr i_vr,
  if_pipeline_vr o_vr
);
localparam INDEX_WIDTH = $clog2(INST_BUFFER_WIDTH);
pipe::ifu2idu_t inst_fifo[INST_BUFFER_WIDTH];
logic [INDEX_WIDTH-1:0] r_ptr, w_ptr;
logic [INDEX_WIDTH:0] count;
always_ff@(posedge i_clock)begin
  if(i_reset || i_flush || i_fencei)begin
    r_ptr <= 0;
    w_ptr <= 0;
    count <= 0;
  end
  else begin
    if(i_vr.valid && i_vr.ready && o_vr.valid && o_vr.ready)begin
      w_ptr <= w_ptr + 1;
      r_ptr <= r_ptr + 1;
    end
    else if(i_vr.valid && i_vr.ready) begin
      w_ptr <= w_ptr + 1;
      count <= count + 1;
    end
    else if(o_vr.valid && o_vr.ready) begin
      r_ptr <= r_ptr + 1;
      count <= count - 1;
    end
  end
end

always_ff@(posedge i_clock)begin
   if(i_vr.valid && i_vr.ready) inst_fifo[w_ptr] <= from_ifu;
end

logic full, empty;
assign full = count == INST_BUFFER_WIDTH;
assign empty = count == 0;
assign i_vr.ready = !full;
assign o_vr.valid = !empty;
assign to_idu = inst_fifo[r_ptr];

endmodule
