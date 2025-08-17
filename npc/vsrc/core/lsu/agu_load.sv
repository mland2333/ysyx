module ysyx_24110006_AGU_LOAD(
  input i_clock,
  if_pipeline_vr.in vr_in,
  if_pipeline_vr.out vr_out,
  input bypass::src_t src,
  input ooo::issue_lsu_t issue_info,
  output lsu::rq_load_t rq_load
);
assign vr_out.valid = vr_in.valid;
assign vr_in.ready = vr_out.ready;
wire [31:0] addr = src.d[0] + issue_info.agu_info.imm;

assign rq_load.addr = addr;
assign rq_load.read_t = issue_info.agu_info.func;
assign rq_load.rob_index = issue_info.rob_index;
assign rq_load.rd = issue_info.rd;
assign rq_load.vrd = issue_info.vrd;
assign rq_load.store_index = issue_info.store_index;

endmodule
