module ysyx_24110006_STORE_IQ #(
    parameter NUM = 16
) (
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    input store_prior,
    input rob::wb_index rob_index,
    input ooo::dispatch_inst_t dispatch_inst,
    input bypass::wakeup_group_t wakeup,
    input rename::commit_group_t commit,
    output ooo::issue_lsu_t issue_inst,
    output rf::rinfo_t reg_rinfo,
    output bypass::src_loction_t loc,
    output rob::store_commit_t store_commit,
    output lsu::older_store_t older_store
);

  typedef struct packed {
    ooo::dispatch_inst_t data;
    rob::wb_index rob_index;
  } store_iq_t;
  localparam INDEX = $clog2(NUM);
  localparam WIDTH = $bits(store_iq_t);
  logic [INDEX-1:0] w_ptr;
  logic [INDEX:0] count;
  logic full, empty;
  logic alloc, free;
  assign full  = count == NUM;
  assign empty = count == 0;
  assign alloc = i_vr.valid && i_vr.ready;
  assign free  = o_vr.valid && o_vr.ready;
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) w_ptr <= 0;
    else if (alloc) w_ptr <= w_ptr + 1;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) begin
      count <= 0;
    end else if (alloc && !free) begin
      count <= count + 1;
    end else if (free && !alloc) begin
      count <= count - 1;
    end
  end
  ISSUE_QUEUE #(
      .WIDTH(WIDTH),
      .NUM(NUM),
      .MODE("HEAD"),
      .T(store_iq_t)
  ) miq (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(i_flush),
      .alloc(alloc),
      .free(free),
      .valid(issue_valid),
      .ctrl(0),
      .alloc_index(w_ptr),
      .free_index(),
      .wakeup(wakeup),
      .commit(commit),
      .alloc_data({dispatch_inst, rob_index}),
      .free_data(select_inst),
      .loc(loc)
  );

  logic issue_valid;
  store_iq_t select_inst;
  assign o_vr.valid = !empty && issue_valid;
  assign i_vr.ready = !full;
  assign issue_inst.agu_info.wen = select_inst.data.mem_wen;
  assign issue_inst.agu_info.imm = select_inst.data.basic_inst_info.imm;
  assign issue_inst.agu_info.func = select_inst.data.basic_inst_info.func;
  assign issue_inst.rob_index = select_inst.rob_index;
  assign issue_inst.rd = select_inst.data.rd;
  assign issue_inst.vrd = select_inst.data.vrd;
  assign reg_rinfo = select_inst.data.reg_rinfo;
  assign store_commit.valid = free;
  assign store_commit.index = select_inst.rob_index;
  rob::wb_index store_index;
  always_ff @(posedge i_clock) begin
    if (i_reset) store_index <= 0;
    else if (alloc) store_index <= rob_index;
  end
  assign older_store.valid = (empty || count == 1 && free) && !store_prior;
  assign older_store.store_index = store_prior ? rob_index : store_index;
endmodule
