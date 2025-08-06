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
  typedef struct packed{
    ooo::dispatch_inst_t data;
    rob::wb_index rob_index;
  }int_iq_t;
  localparam IQ_INDEX = $clog2(INT_IQ_NUM);
  int_iq_t iq[INT_IQ_NUM];
  logic [IQ_INDEX-1:0] w_ptr, r_ptr;
  logic [IQ_INDEX:0] count;
  logic full, empty;
  logic push, pop;
  assign full  = count == INT_IQ_NUM;
  assign empty = count == 0;
  assign push = i_vr.valid && i_vr.ready;
  assign pop = o_vr.valid && o_vr.ready;
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) begin
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
    if (push) iq[w_ptr] <= {dispatch_inst, rob_index};
  end
  logic [INT_IQ_NUM-1:0] info_valid;
  logic [1:0] rs_valid [INT_IQ_NUM];
  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush) info_valid <= 0;
    else if(push && pop)begin
      info_valid[w_ptr] <= 1;
      info_valid[r_ptr] <= 0;
    end else if (push) begin
      info_valid[w_ptr] <= 1;
    end else if (pop) begin
      info_valid[r_ptr] <= 0;
    end
  end
  always_ff@(posedge i_clock)begin
    for(int i = 0; i<INT_IQ_NUM; i++)begin
      if(i_reset || i_flush) rs_valid[i] <= 0;
      else if(push && w_ptr == i)begin
        rs_valid[i][0] <= !dispatch_inst.need_rs[0] || dispatch_inst.rs_valid[0] ||
          reg_winfo.valid && reg_winfo.rd == dispatch_inst.reg_rinfo.rs1 && reg_winfo.wen;
        rs_valid[i][1] <= !dispatch_inst.need_rs[1] || dispatch_inst.rs_valid[1] ||
          reg_winfo.valid && reg_winfo.rd == dispatch_inst.reg_rinfo.rs2 && reg_winfo.wen;
      end
      else if(reg_winfo.valid && info_valid[i] && reg_winfo.wen)begin
        rs_valid[i][0] <= reg_winfo.rd == iq[i].data.reg_rinfo.rs1 || rs_valid[i][0];
        rs_valid[i][1] <= reg_winfo.rd == iq[i].data.reg_rinfo.rs2 || rs_valid[i][1];
      end
      else if(pop && r_ptr == i)
        rs_valid[i] <= 0;
    end
  end
  logic issue_valid;
  int_iq_t select_inst;
  assign issue_valid = rs_valid[r_ptr][0] && rs_valid[r_ptr][1];
  assign o_vr.valid = !empty && issue_valid && info_valid[r_ptr];
  assign i_vr.ready = !full;
  assign select_inst = iq[r_ptr];
  assign issue_inst.data = select_inst.data.basic_inst_info;
  assign reg_rinfo = select_inst.data.reg_rinfo;
  assign issue_inst.rob_index = select_inst.rob_index;
endmodule

