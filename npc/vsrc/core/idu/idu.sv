`include "common_config.sv"
module ysyx_24110006_IDU (
    input i_clock,
    input i_reset,
    input pipe::ifu2idu_t from_ifu,
    output ooo::idu2rename_t to_rename,
    input i_flush,

    if_pipeline_vr.in  i_vr,
    if_pipeline_vr.out o_vr
);

  pipe::ifu2idu_t ifu_data;

  wire update_reg;
  always @(posedge i_clock) begin
    if (update_reg) ifu_data <= from_ifu;
  end
  logic r_valid;
  assign r_valid = i_vr.valid & ~i_flush;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) o_vr.valid <= 0;
    else if (r_ready && r_valid && !o_vr.valid) begin
      o_vr.valid <= 1;
    end else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) begin
      o_vr.valid <= 0;
    end
  end
  reg r_ready;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) r_ready <= 1;
    else if (r_ready && r_valid && !o_vr.valid) r_ready <= 0;
    else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) r_ready <= 1;
  end
  assign i_vr.ready = (r_ready | o_vr.ready);
  assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush;

  DECODER mdecoder0(
    .ifu_data(ifu_data.d1),
    .to_rename(to_rename.d[0])
  );
  DECODER mdecoder1(
    .ifu_data(ifu_data.d2),
    .to_rename(to_rename.d[1])
  );
  assign to_rename.inst_valid = ifu_data.inst_valid;
endmodule
