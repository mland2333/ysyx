`include "common_config.sv"
module ysyx_24110006_INT_IQ #(
    parameter NUM = 32
) (
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    input rob::wb_index rob_index,
    input ooo::dispatch_inst_t dispatch_inst,
    output bypass::wakeup_t int_wakeup,
    input bypass::wakeup_group_t wakeup,
    input rename::commit_group_t commit,
    output ooo::issue_int_t issue_inst,
    output rf::rinfo_t reg_rinfo,
    output bypass::src_loction_t loc
);
  typedef struct packed {
    ooo::dispatch_inst_t data;
    rob::wb_index rob_index;
  } int_iq_t;
  localparam INDEX = $clog2(NUM);
  localparam WIDTH = $bits(int_iq_t);
  FREE_LIST #(
      .WIDTH(INDEX),
      .NUM  (NUM)
  ) free_list (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(i_flush),
      .pop(alloc),
      .push(free),
      .data_in(free_index),
      .data_out(alloc_index),
      .empty(full),
      .full(empty)
  );
  logic alloc, free, full, empty;
  logic [INDEX-1:0] alloc_index, free_index;

  ISSUE_QUEUE #(
      .WIDTH(WIDTH),
      .NUM  (NUM),
      .MODE ("AGE"),
      .T(int_iq_t)
  ) miq (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(i_flush),
      .alloc(alloc),
      .free(free),
      .valid(issue_valid),
      .ctrl(~((NUM)'(0))),
      .alloc_index(alloc_index),
      .free_index(free_index),
      .wakeup(wakeup),
      .commit(commit),
      .alloc_data({dispatch_inst, rob_index}),
      .free_data(select_inst),
      .loc(loc)
  );

  assign alloc = i_vr.valid && i_vr.ready;
  assign free  = o_vr.valid && o_vr.ready;
  logic issue_valid;
  int_iq_t select_inst;
  assign o_vr.valid = !empty && issue_valid;
  assign i_vr.ready = !full;
  assign issue_inst.data = select_inst.data.basic_inst_info;
  assign reg_rinfo = select_inst.data.reg_rinfo;
  assign issue_inst.rob_index = select_inst.rob_index;
  assign issue_inst.reg_wen = select_inst.data.reg_wen;
  assign issue_inst.rd = select_inst.data.rd;
  assign issue_inst.vrd = select_inst.data.vrd;
  assign issue_inst.bp_info = select_inst.data.bp_info;
  assign int_wakeup.valid = issue_valid && select_inst.data.reg_wen;
  assign int_wakeup.prd = select_inst.data.rd;
endmodule

