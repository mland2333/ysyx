`include "common_config.sv"
module ysyx_24110006_LOAD_IQ #(
    parameter NUM = 32
) (
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    input rob::wb_index rob_index,
    input ooo::dispatch_inst_t dispatch_inst,
    input bypass::wakeup_group_t wakeup,
    input rename::commit_group_t commit,
    output ooo::issue_lsu_t issue_inst,
    output rf::rinfo_t reg_rinfo,
    output bypass::src_loction_t loc,
    input lsu::older_store_t older_store,
    input rob::store_commit_t store_commit
);

  typedef struct packed {
    ooo::dispatch_inst_t data;
    rob::wb_index rob_index;
  } load_iq_t;
  localparam INDEX = $clog2(NUM);
  localparam WIDTH = $bits(load_iq_t);
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
  assign alloc = i_vr.valid && i_vr.ready;
  assign free  = o_vr.valid && o_vr.ready;
  rob::wb_index store_index[NUM];
  logic [NUM-1:0] store_valid;
  always_ff @(posedge i_clock) begin
    for(int i = 0; i<NUM; i++)begin
      if(i_reset) store_valid[i] <= 0;
      else if(alloc && alloc_index == i) begin
        store_valid[i] <= older_store.valid;
      end
      else if(store_commit.valid && store_commit.index == store_index[i])
        store_valid[i] <= 1;
      else if(free && free_index == i)
        store_valid[i] <= 0;
    end
  end
  always_ff@(posedge i_clock)begin
    if(alloc) store_index[alloc_index] <= older_store.store_index;
  end
  ISSUE_QUEUE #(
      .WIDTH(WIDTH),
      .NUM  (NUM),
      .MODE ("AGE"),
      .T(load_iq_t)
  ) miq (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(i_flush),
      .alloc(alloc),
      .free(free),
      .valid(issue_valid),
      .ctrl(store_valid),
      .alloc_index(alloc_index),
      .free_index(free_index),
      .wakeup(wakeup),
      .commit(commit),
      .alloc_data({dispatch_inst, rob_index}),
      .free_data(select_inst),
      .loc(loc)
  );
  
  load_iq_t select_inst;
  logic issue_valid;
  assign o_vr.valid = !empty && issue_valid;
  assign i_vr.ready = !full;
  assign reg_rinfo = select_inst.data.reg_rinfo;
  assign issue_inst.agu_info.wen = select_inst.data.mem_wen;
  assign issue_inst.agu_info.imm = select_inst.data.basic_inst_info.imm;
  assign issue_inst.agu_info.func = select_inst.data.basic_inst_info.func;
  assign issue_inst.rob_index = select_inst.rob_index;
  assign issue_inst.rd = select_inst.data.rd;
  assign issue_inst.vrd = select_inst.data.vrd;
  assign issue_inst.store_index = store_index[free_index];
endmodule

