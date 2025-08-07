`include "common_config.sv"
module ysyx_24110006_ROB #(
    parameter ROB_NUM = `ROB_NUM
) (
    input i_clock,
    input i_reset,
    if_pipeline_vr.in vr_in,
    input rob::inst_info_t dispatch_inst,
    input rob::commit_info_t commit_int,
    input rob::commit_info_t commit_lsu,
    input rob::store_commit_t commit_store,
    output rob::wb_index rob_index,
    output logic retire_valid,
    output ooo::retire_info_t retire_info,
    output rob::rob_t rob_out,
    output pipe::reg_winfo_t reg_winfo,
    output store_retire
);

  localparam ROB_INDEX = $clog2(ROB_NUM);
  rob::rob_t robs[ROB_NUM];
  logic [ROB_INDEX-1:0] w_ptr, r_ptr;
  logic [ROB_INDEX:0] count;
  logic full, empty;
  logic push, pop;
  assign full = count == ROB_NUM;
  assign empty = count == 0;
  assign vr_in.ready = !full;
  assign push = vr_in.valid && vr_in.ready;
  assign pop = robs[r_ptr].valid;
  always_ff @(posedge i_clock) begin
    if (i_reset || flush) begin
      w_ptr <= 0;
      r_ptr <= 0;
      count <= 0;
    end else if (push && pop) begin
      w_ptr <= w_ptr + 1;
      r_ptr <= r_ptr + 1;
    end else if (push) begin
      w_ptr <= w_ptr + 1;
      count <= count + 1;
    end else if (pop) begin
      r_ptr <= r_ptr + 1;
      count <= count - 1;
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < ROB_NUM; i++) begin
      if (i_reset || flush) robs[i].valid <= 0;
      else if (push && w_ptr == i) robs[i].inst_info <= dispatch_inst;
      else if (commit_int.valid && commit_int.index[ROB_INDEX-1:0] == i) begin
        robs[i].result <= commit_int.result;
        robs[i].valid  <= 1;
        robs[i].type_store <= 0;
      end else if (commit_lsu.valid && commit_lsu.index[ROB_INDEX-1:0] == i) begin
        robs[i].result <= commit_lsu.result;
        robs[i].valid  <= 1;
        robs[i].type_store <= 0;
      end else if(commit_store.valid && commit_store.index[ROB_INDEX-1:0] == i)begin
        robs[i].valid <= 1;
        robs[i].result <= 0;
        robs[i].type_store <= 1;
      end else if (robs[i].valid && r_ptr == i) robs[i].valid <= 0;
    end
  end

  /* always_ff @(posedge i_clock) begin */
  /*   if (push) rob_index <= w_ptr; */
  /* end */
  assign rob_index = {w_ptr < r_ptr, w_ptr};
  logic flush;
  assign flush = robs[r_ptr].result.flush && retire_valid;
  assign retire_valid = robs[r_ptr].valid;
  assign reg_winfo.valid = retire_valid;
  assign reg_winfo.wdata = robs[r_ptr].result.result;
  assign reg_winfo.rd = robs[r_ptr].inst_info.prd;
  assign reg_winfo.wen = robs[r_ptr].inst_info.reg_wen;
  assign retire_info.flush_retire = flush;
  assign retire_info.retire = robs[r_ptr].inst_info.reg_wen && robs[r_ptr].inst_info.vrd != 0 && retire_valid;
  assign retire_info.has_old_map = robs[r_ptr].inst_info.has_old_map;
  assign retire_info.old_index = robs[r_ptr].inst_info.old_index;
  assign retire_info.vrd = robs[r_ptr].inst_info.vrd;
  assign retire_info.prd = robs[r_ptr].inst_info.prd;
  assign rob_out = robs[r_ptr];
  assign store_retire = retire_valid && robs[r_ptr].type_store;
endmodule
