`include "common_config.sv"
module ysyx_24110006_INT_IQ #(
    parameter INT_IQ_NUM = 32
) (
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    input rob::wb_index rob_index,
    input ooo::dispatch_inst_t dispatch_inst,
    input pipe::reg_winfo_t reg_winfo,
    output ooo::issue_int_t issue_inst,
    output pipe::reg_rinfo_t reg_rinfo
);
  typedef struct packed {
    ooo::dispatch_inst_t data;
    rob::wb_index rob_index;
  } int_iq_t;
  localparam IQ_INDEX = $clog2(INT_IQ_NUM);
  FREE_LIST #(
      .WIDTH(IQ_INDEX),
      .NUM  (INT_IQ_NUM)
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
  logic [IQ_INDEX-1:0] alloc_index, free_index;
  assign alloc = i_vr.valid && i_vr.ready;
  assign free  = o_vr.valid && o_vr.ready;
  int_iq_t iq[INT_IQ_NUM];

  logic [INT_IQ_NUM-1:0] info_valid;
  logic [1:0] rs_valid[INT_IQ_NUM];
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) info_valid <= 0;
    else if (alloc && free) begin
      info_valid[alloc_index] <= 1;
      info_valid[free_index]  <= 0;
    end else if (alloc) begin
      info_valid[alloc_index] <= 1;
    end else if (free) begin
      info_valid[free_index] <= 0;
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < INT_IQ_NUM; i++) begin
      if (i_reset || i_flush) rs_valid[i] <= 0;
      else if (alloc && alloc_index == i) begin
        rs_valid[i][0] <= !dispatch_inst.need_rs[0] || dispatch_inst.rs_valid[0] ||
          reg_winfo.valid && reg_winfo.rd == dispatch_inst.reg_rinfo.rs1 && reg_winfo.wen;
        rs_valid[i][1] <= !dispatch_inst.need_rs[1] || dispatch_inst.rs_valid[1] ||
          reg_winfo.valid && reg_winfo.rd == dispatch_inst.reg_rinfo.rs2 && reg_winfo.wen;
      end else if (reg_winfo.valid && info_valid[i] && reg_winfo.wen) begin
        rs_valid[i][0] <= reg_winfo.rd == iq[i].data.reg_rinfo.rs1 || rs_valid[i][0];
        rs_valid[i][1] <= reg_winfo.rd == iq[i].data.reg_rinfo.rs2 || rs_valid[i][1];
      end else if (free && free_index == i) rs_valid[i] <= 0;
    end
  end
  always_ff @(posedge i_clock) begin
    if (alloc) iq[alloc_index] <= {dispatch_inst, rob_index};
  end
  logic [IQ_INDEX-1:0] issue_index;
  logic issue_valid;

  typedef struct packed {
    logic valid;
    rob::wb_index age;
    logic [IQ_INDEX-1:0] index;
  } entry_t;
  function entry_t compare_entry(input entry_t a, input entry_t b);
    if (a.valid && !b.valid) return a;
    else if (!a.valid && b.valid) return b;
    else if (!a.valid && !b.valid) return 0;
    else begin
      if (rob::is_older(a.age, b.age)) return a;
      else return b;
    end
  endfunction
  entry_t nodes [INT_IQ_NUM*2];
  generate
    for (genvar i = 0; i < INT_IQ_NUM; i++) begin : leaf_init
      always_comb begin
        nodes[i+INT_IQ_NUM].valid = rs_valid[i][0] && rs_valid[i][1] && info_valid[i];
        nodes[i+INT_IQ_NUM].age   = iq[i].rob_index;
        nodes[i+INT_IQ_NUM].index = 5'(i);
      end
    end
  endgenerate

  generate
    for (genvar level = 0; level < $clog2(INT_IQ_NUM); level++) begin : tree_level
      for (genvar j = (1 << level); j < (1 << (level + 1)); j++) begin : tree_node
        assign nodes[j] = compare_entry(nodes[j*2], nodes[j*2+1]);
      end
    end
  endgenerate

  assign issue_valid = nodes[1].valid;
  assign issue_index = nodes[1].index;
  assign free_index  = issue_index;
  int_iq_t select_inst;
  assign select_inst = iq[issue_index];
  assign o_vr.valid = !empty && issue_valid;
  assign i_vr.ready = !full;
  assign issue_inst.data = select_inst.data.basic_inst_info;
  assign reg_rinfo = select_inst.data.reg_rinfo;
  assign issue_inst.rob_index = select_inst.rob_index;
endmodule

