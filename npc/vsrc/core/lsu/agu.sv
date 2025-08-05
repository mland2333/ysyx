module ysyx_24110006_AGU(
  input i_clock,
  if_pipeline_vr.in vr_in,
  if_pipeline_vr.out vr_load,
  if_pipeline_vr.out vr_store,
  input pipe::reg_rdata_t reg_rdata,
  input ooo::issue_lsu_t issue_info,
  output lsu::rq_store_t rq_store,
  output lsu::rq_load_t rq_load
);
assign vr_store.valid = vr_in.valid && issue_info.agu_info.wen;
assign vr_load.valid = vr_in.valid && !issue_info.agu_info.wen;
assign vr_in.ready = (issue_info.agu_info.wen && vr_store.ready || !issue_info.agu_info.wen && vr_load.ready);
wire [31:0] addr = reg_rdata.r1 + issue_info.agu_info.imm;
assign rq_store.addr = addr;
assign rq_store.wdata = reg_rdata.r2;
assign rq_store.wmask = issue_info.agu_info.wen ? (issue_info.agu_info.func == 4'b0 ? 4'b0001 : issue_info.agu_info.func == 4'b0001 ? 4'b0011 : 4'b1111) : 0;

assign rq_load.addr = addr;
assign rq_load.read_t = issue_info.agu_info.func;
assign rq_load.rob_index = issue_info.rob_index;

/* assign lsu_info.addr = reg_rdata.r1 + issue_info.agu_info.imm; */
/* assign lsu_info.wdata = reg_rdata.r2; */
/* assign lsu_info.read_t = issue_info.agu_info.func; */
/* assign lsu_info.wmask = issue_info.agu_info.wen ? (issue_info.agu_info.func == 4'b0 ? 4'b0001 : issue_info.agu_info.func == 4'b0001 ? 4'b0011 : 4'b1111) : 0; */
/* assign lsu_info.rob_index = issue_info.rob_index; */
endmodule
