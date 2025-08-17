module ysyx_24110006_AGU_STORE (
    input i_clock,
    if_pipeline_vr.in vr_in,
    if_pipeline_vr.out vr_out,
    input bypass::src_t src,
    input ooo::issue_lsu_t issue_info,
    output lsu::rq_store_t rq_store
);
  assign vr_out.valid = vr_in.valid;
  assign vr_in.ready  = vr_out.ready;
  wire [31:0] addr = src.d[0] + issue_info.agu_info.imm;
  assign rq_store.addr = addr;
  assign rq_store.wdata = src.d[1];
  assign rq_store.wmask = issue_info.agu_info.wen ? (issue_info.agu_info.func == 4'b0 ? 4'b0001 : issue_info.agu_info.func == 4'b0001 ? 4'b0011 : 4'b1111) : 0;
  assign rq_store.rob_index = issue_info.rob_index;

endmodule
