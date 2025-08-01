module ysyx_24110006_AGU(
  input i_clock,
  if_pipeline_vr.in vr_in,
  if_pipeline_vr.out vr_out,
  input pipe::reg_rdata_t reg_rdata,
  input ooo::issue_lsu_t issue_info,
  output ooo::lsu_info_t lsu_info
);
assign vr_out.valid = vr_in.valid;
assign vr_in.ready = vr_out.ready;
assign lsu_info.wen = issue_info.agu_info.wen;
assign lsu_info.addr = reg_rdata.r1 + issue_info.agu_info.imm;
assign lsu_info.wdata = reg_rdata.r2;
assign lsu_info.read_t = issue_info.agu_info.func;
assign lsu_info.wmask = issue_info.agu_info.wen ? (issue_info.agu_info.func == 4'b0 ? 4'b0001 : issue_info.agu_info.func == 4'b0001 ? 4'b0011 : 4'b1111) : 0;
assign lsu_info.rob_index = issue_info.rob_index;
endmodule
