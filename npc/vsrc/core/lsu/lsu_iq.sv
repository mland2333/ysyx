module ysyx_24110006_LSU_IQ #(
    parameter LSU_IQ_NUM = 32
) (
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    input rob::wb_index rob_index,
    input ooo::dispatch_inst_t dispatch_inst,
    input bypass::wakeup_t lsu_wakeup,
    output bypass::wakeup_t int_wakeup,
    output ooo::issue_lsu_t issue_inst,
    output rf::rinfo_t reg_rinfo,
    output bypass::src_loction_t loc,
    output rob::store_commit_t store_commit
);
  typedef struct packed {
    ooo::dispatch_inst_t data;
    rob::wb_index rob_index;
  } lsu_iq_t;
  localparam IQ_INDEX = $clog2(LSU_IQ_NUM);
  lsu_iq_t iq[LSU_IQ_NUM];
  logic [IQ_INDEX-1:0] w_ptr, r_ptr;
  logic [IQ_INDEX:0] count;
  logic full, empty;
  logic push, pop;
  assign full  = count == LSU_IQ_NUM;
  assign empty = count == 0;
  assign push  = i_vr.valid && i_vr.ready;
  assign pop   = o_vr.valid && o_vr.ready;
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
  logic [LSU_IQ_NUM-1:0] info_valid;
  logic [1:0] rs_valid[LSU_IQ_NUM];
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) info_valid <= 0;
    else if (push && pop) begin
      info_valid[w_ptr] <= 1;
      info_valid[r_ptr] <= 0;
    end else if (push) begin
      info_valid[w_ptr] <= 1;
    end else if (pop) begin
      info_valid[r_ptr] <= 0;
    end
  end

  always_ff @(posedge i_clock) begin
    for (int i = 0; i < LSU_IQ_NUM; i++) begin
      if (i_reset || i_flush) rs_valid[i] <= 0;
      else if (push && w_ptr == i) begin
        rs_valid[i][0] <= !dispatch_inst.need_rs[0] || dispatch_inst.rs_valid[0] ||
          int_wakeup.valid && int_wakeup.rd == dispatch_inst.reg_rinfo.rs1 ||
          lsu_wakeup.valid && lsu_wakeup.rd == dispatch_inst.reg_rinfo.rs1;
        rs_valid[i][1] <= !dispatch_inst.need_rs[1] || dispatch_inst.rs_valid[1] ||
          int_wakeup.valid && int_wakeup.rd == dispatch_inst.reg_rinfo.rs2 ||
          lsu_wakeup.valid && lsu_wakeup.rd == dispatch_inst.reg_rinfo.rs2;
      end else if (lsu_wakeup.valid && int_wakeup.valid && info_valid[i]) begin
        rs_valid[i][0] <= int_wakeup.rd == iq[i].data.reg_rinfo.rs1 || 
          lsu_wakeup.rd == iq[i].data.reg_rinfo.rs1 || rs_valid[i][0];
        rs_valid[i][1] <= int_wakeup.rd == iq[i].data.reg_rinfo.rs2 || 
          lsu_wakeup.rd == iq[i].data.reg_rinfo.rs2 || rs_valid[i][1];
      end else if (lsu_wakeup.valid && info_valid[i]) begin
        rs_valid[i][0] <= lsu_wakeup.rd == iq[i].data.reg_rinfo.rs1 || rs_valid[i][0];
        rs_valid[i][1] <= lsu_wakeup.rd == iq[i].data.reg_rinfo.rs2 || rs_valid[i][1];
      end else if (int_wakeup.valid && info_valid[i]) begin
        rs_valid[i][0] <= int_wakeup.rd == iq[i].data.reg_rinfo.rs1 || rs_valid[i][0];
        rs_valid[i][1] <= int_wakeup.rd == iq[i].data.reg_rinfo.rs2 || rs_valid[i][1];
      end else if (pop && r_ptr == i) rs_valid[i] <= 0;
    end
  end

  bypass::src_loction_t locs[LSU_IQ_NUM];
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < LSU_IQ_NUM; i++) begin
      if (i_reset || i_flush) begin
        locs[i].loc[0] <= bypass::none;
        locs[i].loc[1] <= bypass::none;
      end else if (push && w_ptr == i) begin
        if (dispatch_inst.need_rs[0] && dispatch_inst.rs_valid[0])
          locs[i].loc[0] <= bypass::from_reg;
        else if (int_wakeup.valid && int_wakeup.rd == dispatch_inst.reg_rinfo.rs1)
          locs[i].loc[0] <= bypass::from_int;
        else if (lsu_wakeup.valid && lsu_wakeup.rd == dispatch_inst.reg_rinfo.rs1)
          locs[i].loc[0] <= bypass::from_lsu;
        if (dispatch_inst.need_rs[1] && dispatch_inst.rs_valid[1])
          locs[i].loc[1] <= bypass::from_reg;
        else if (int_wakeup.valid && int_wakeup.rd == dispatch_inst.reg_rinfo.rs2)
          locs[i].loc[1] <= bypass::from_int;
        else if (lsu_wakeup.valid && lsu_wakeup.rd == dispatch_inst.reg_rinfo.rs2)
          locs[i].loc[1] <= bypass::from_lsu;
      end else if (lsu_wakeup.valid && int_wakeup.valid && info_valid[i]) begin
        if (iq[i].data.need_rs[0] && lsu_wakeup.rd == iq[i].data.reg_rinfo.rs1 && !rs_valid[i][0])
          locs[i].loc[0] <= bypass::from_lsu;
        else if(iq[i].data.need_rs[0] && int_wakeup.rd == iq[i].data.reg_rinfo.rs1 && !rs_valid[i][0])
          locs[i].loc[0] <= bypass::from_int;
        else if (iq[i].data.need_rs[0] || rs_valid[i][0] && (!pop || r_ptr != i))
          locs[i].loc[0] <= bypass::from_reg;
        if (iq[i].data.need_rs[1] && lsu_wakeup.rd == iq[i].data.reg_rinfo.rs2 && !rs_valid[i][1])
          locs[i].loc[1] <= bypass::from_lsu;
        else if(iq[i].data.need_rs[1] && int_wakeup.rd == iq[i].data.reg_rinfo.rs2 && !rs_valid[i][1])
          locs[i].loc[1] <= bypass::from_int;
        else if (iq[i].data.need_rs[1] || rs_valid[i][1] && (!pop || r_ptr != i))
          locs[i].loc[1] <= bypass::from_reg;
      end else if (lsu_wakeup.valid && info_valid[i]) begin
        if (iq[i].data.need_rs[0] && lsu_wakeup.rd == iq[i].data.reg_rinfo.rs1 && !rs_valid[i][0])
          locs[i].loc[0] <= bypass::from_lsu;
        else if (iq[i].data.need_rs[0] || rs_valid[i][0] && (!pop || r_ptr != i))
          locs[i].loc[0] <= bypass::from_reg;
        if (iq[i].data.need_rs[1] && lsu_wakeup.rd == iq[i].data.reg_rinfo.rs2 && !rs_valid[i][1])
          locs[i].loc[1] <= bypass::from_lsu;
        else if (iq[i].data.need_rs[1] || rs_valid[i][1] && (!pop || r_ptr != i))
          locs[i].loc[1] <= bypass::from_reg;
      end else if (pop && r_ptr == i) begin
        locs[i].loc[0] <= bypass::none;
        locs[i].loc[1] <= bypass::none;
      end else if (int_wakeup.valid && info_valid[i]) begin
        if (iq[i].data.need_rs[0] && int_wakeup.rd == iq[i].data.reg_rinfo.rs1 && !rs_valid[i][0])
          locs[i].loc[0] <= bypass::from_int;
        else if (iq[i].data.need_rs[0] || rs_valid[i][0] && (!pop || r_ptr != i))
          locs[i].loc[0] <= bypass::from_reg;
        if (iq[i].data.need_rs[1] && int_wakeup.rd == iq[i].data.reg_rinfo.rs2 && !rs_valid[i][1])
          locs[i].loc[1] <= bypass::from_int;
        else if (iq[i].data.need_rs[1] || rs_valid[i][1] && (!pop || r_ptr != i))
          locs[i].loc[1] <= bypass::from_reg;
      end else begin
        if (iq[i].data.need_rs[0] || rs_valid[i][0] && (!pop || r_ptr != i))
          locs[i].loc[0] <= bypass::from_reg;
        if (iq[i].data.need_rs[1] || rs_valid[i][1] && (!pop || r_ptr != i))
          locs[i].loc[1] <= bypass::from_reg;
        /* if (iq[i].data.need_rs[1]) locs[i].loc[1] <= bypass::from_reg; */
      end
    end
  end

  logic issue_valid;
  lsu_iq_t select_inst;
  assign issue_valid = rs_valid[r_ptr][0] && rs_valid[r_ptr][1];
  assign o_vr.valid = !empty && issue_valid && info_valid[r_ptr];
  assign i_vr.ready = !full;
  assign select_inst = iq[r_ptr];
  assign issue_inst.agu_info.wen = select_inst.data.mem_wen;
  assign issue_inst.agu_info.imm = select_inst.data.basic_inst_info.imm;
  assign issue_inst.agu_info.func = select_inst.data.basic_inst_info.func;
  assign issue_inst.rob_index = select_inst.rob_index;
  assign issue_inst.rd = select_inst.data.rd;
  assign issue_inst.vrd = select_inst.data.vrd;
  assign reg_rinfo = select_inst.data.reg_rinfo;
  assign store_commit.valid = o_vr.valid && o_vr.ready && select_inst.data.mem_wen;
  assign store_commit.index = select_inst.rob_index;
  assign loc = locs[r_ptr];
endmodule
