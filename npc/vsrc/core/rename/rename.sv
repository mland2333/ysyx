module ysyx_24110006_RENAME #(
    parameter PREG_NUM = 64
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input rename::retire_t retire_info,
    input rename::commit_t commit_int,
    commit_lsu,
    input bypass::wakeup_t int_wakeup,
    lsu_wakeup,
    input ooo::idu2rename_t from_idu,
    output ooo::dispatch_info_t dispatch_info,
`ifdef CONFIG_SIM
    output logic [31:0][5:0] o_rat,
`endif
    if_pipeline_vr i_vr,
    if_pipeline_vr o_vr
);
  logic r_valid;
  assign r_valid = i_vr.valid & ~in_flush & !full;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) o_vr.valid <= 0;
    else if (r_ready && r_valid && !o_vr.valid) begin
      o_vr.valid <= 1;
    end else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) begin
      o_vr.valid <= 0;
    end
  end
  reg r_ready;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) r_ready <= 1;
    else if (r_ready && r_valid && !o_vr.valid) r_ready <= 0;
    else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) r_ready <= 1;
  end
  assign i_vr.ready = (r_ready || o_vr.ready) && !full;
  logic update_reg;
  assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush && !full;

  localparam PREG_NUM_INDEX = $clog2(PREG_NUM);
  typedef struct packed {
    logic [PREG_NUM-1:0][PREG_NUM_INDEX-1:0] preg_index;
    logic [PREG_NUM_INDEX-1:0] r_ptr, w_ptr;
    logic [PREG_NUM_INDEX:0] count;
  } free_list_t;

  free_list_t free_list, free_list_backup;
  logic full, empty;
  logic need_alloc;
  logic flush_retire, in_flush;
  assign full = free_list.count == 0;
  assign empty = free_list.count == PREG_NUM;
  assign need_alloc = r_valid && from_idu.reg_wen && i_vr.ready && from_idu.vrd != 0 && !i_flush;
  always_ff @(posedge i_clock) begin
    flush_retire <= retire_info.flush;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      free_list.r_ptr <= 0;
      free_list.w_ptr <= 0;
      free_list.count <= PREG_NUM;
    end else if (flush_retire) begin
      free_list.r_ptr <= free_list_backup.r_ptr;
      free_list.w_ptr <= free_list_backup.w_ptr;
      free_list.count <= free_list_backup.count;
    end else begin
      if (need_alloc && retire_info.valid && retire_info.has_old_map) begin
        free_list.w_ptr <= free_list.w_ptr + 1;
        free_list.r_ptr <= free_list.r_ptr + 1;
      end else if (retire_info.valid && retire_info.has_old_map) begin
        free_list.w_ptr <= free_list.w_ptr + 1;
        free_list.count <= free_list.count + 1;
      end else if (need_alloc && !full) begin
        free_list.r_ptr <= free_list.r_ptr + 1;
        free_list.count <= free_list.count - 1;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      free_list_backup.r_ptr <= 0;
      free_list_backup.w_ptr <= 0;
      free_list_backup.count <= PREG_NUM;
    end else begin
      if (retire_info.valid) begin
        free_list_backup.r_ptr <= free_list_backup.r_ptr + 1;
        if (retire_info.has_old_map) free_list_backup.w_ptr <= free_list_backup.w_ptr + 1;
        else free_list_backup.count <= free_list_backup.count - 1;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < PREG_NUM; i++) free_list.preg_index[i] <= (PREG_NUM_INDEX)'(i);
    end else if (flush_retire) free_list.preg_index <= free_list_backup.preg_index;
    else if (retire_info.valid && retire_info.has_old_map)
      free_list.preg_index[free_list.w_ptr] <= retire_info.old_index;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < PREG_NUM; i++) free_list_backup.preg_index[i] <= (PREG_NUM_INDEX)'(i);
    end else if (retire_info.valid && retire_info.has_old_map)
      free_list_backup.preg_index[free_list_backup.w_ptr] <= retire_info.old_index;
  end

  ooo::idu2rename_t idu_data;
  always_ff @(posedge i_clock) begin
    if (update_reg) idu_data <= from_idu;
  end

  rf::preg rat [32];
  rf::preg arat[32];
  typedef enum {
    IDLE,
    MAPPED,
    COMMIT,
    READY
  } reg_state_t;
  reg_state_t reg_state[32], areg_state[32];
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) reg_state[i] <= IDLE;
      else if (flush_retire) begin
        reg_state[i] <= areg_state[i];
      end else begin
        if (need_alloc && !full && from_idu.vrd != 0 && from_idu.vrd == i) reg_state[i] <= MAPPED;
        else if (commit_int.valid && commit_int.prd == rat[commit_int.vrd] && commit_int.vrd == i)
          reg_state[i] <= COMMIT;
        else if (commit_lsu.valid && commit_lsu.prd == rat[commit_lsu.vrd] && commit_lsu.vrd == i)
          reg_state[i] <= COMMIT;
        else if (retire_info.valid && retire_info.prd == rat[retire_info.vrd] && retire_info.vrd == i)
          reg_state[i] <= READY;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < 32; i++) areg_state[i] <= IDLE;
    end else begin
      if (retire_info.valid) areg_state[retire_info.vrd] <= READY;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < 32; i++) rat[i] <= 0;
    end else if (flush_retire) begin
      rat <= arat;
    end else begin
      if (need_alloc && !full && from_idu.vrd != 0)
        rat[from_idu.vrd] <= free_list.preg_index[free_list.r_ptr];
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < 32; i++) arat[i] <= 0;
    end else if (retire_info.valid) begin
      arat[retire_info.vrd] <= retire_info.prd;
    end
  end
  logic [PREG_NUM_INDEX-1:0] prd, rs1, rs2;
  logic [1:0] rs_zero;
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      rs1 <= 0;
      rs2 <= 0;
      rs_zero <= 0;
    end else if (update_reg) begin
      rs1 <= rat[from_idu.vrs1];
      rs2 <= rat[from_idu.vrs2];
      rs_zero <= {from_idu.vrs2 == 0, from_idu.vrs1 == 0};
    end
  end

  logic has_old_map;
  logic [`REG_NUM_INDEX-1:0] old_index;
  always_ff @(posedge i_clock) begin
    if (update_reg) begin
      has_old_map <= reg_state[from_idu.vrd] != IDLE;
      old_index   <= rat[from_idu.vrd];
    end
  end
  logic [1:0] rs_valid;
  always_ff @(posedge i_clock) begin
    if (update_reg) begin
      rs_valid[0] <= reg_state[from_idu.vrs1] != MAPPED ||
        from_idu.vrs1 == 0 ||
        retire_info.valid && retire_info.prd == rat[from_idu.vrs1] ||
        commit_int.valid && commit_int.prd == rat[from_idu.vrs1] ||
        commit_lsu.valid && commit_lsu.prd == rat[from_idu.vrs1] ||
        int_wakeup.valid && int_wakeup.rd == rat[from_idu.vrs1] ||
        lsu_wakeup.valid && lsu_wakeup.rd == rat[from_idu.vrs1];
      rs_valid[1] <= reg_state[from_idu.vrs2] != MAPPED ||
        from_idu.vrs2 == 0 ||
        retire_info.valid && retire_info.prd == rat[from_idu.vrs2] ||
        commit_int.valid && commit_int.prd == rat[from_idu.vrs2] ||
        commit_lsu.valid && commit_lsu.prd == rat[from_idu.vrs2] ||
        int_wakeup.valid && int_wakeup.rd == rat[from_idu.vrs2] ||
        lsu_wakeup.valid && lsu_wakeup.rd == rat[from_idu.vrs2];
    end
    else if(!o_vr.ready) begin
      rs_valid[0] <= reg_state[idu_data.vrs1] != MAPPED ||
        idu_data.vrs1 == 0 ||
        retire_info.valid && retire_info.prd == rs1 ||
        commit_int.valid && commit_int.prd == rs1 ||
        commit_lsu.valid && commit_lsu.prd == rs1 ||
        int_wakeup.valid && int_wakeup.rd == rs1 ||
        lsu_wakeup.valid && lsu_wakeup.rd == rs1 || rs_valid[0];
      rs_valid[1] <= reg_state[idu_data.vrs2] != MAPPED ||
        idu_data.vrs2 == 0 ||
        retire_info.valid && retire_info.prd == rs2 ||
        commit_int.valid && commit_int.prd == rs2 ||
        commit_lsu.valid && commit_lsu.prd == rs2 ||
        int_wakeup.valid && int_wakeup.rd == rs2 ||
        lsu_wakeup.valid && lsu_wakeup.rd == rs2 || rs_valid[1];
    end
  end

  assign dispatch_info.basic_inst_info.op = idu_data.op;
  assign dispatch_info.basic_inst_info.func = idu_data.func;
  assign dispatch_info.basic_inst_info.pc = idu_data.pc;
  assign dispatch_info.basic_inst_info.imm = idu_data.imm;
  assign dispatch_info.prd = rat[idu_data.vrd];
  assign dispatch_info.vrd = idu_data.vrd;
  assign dispatch_info.mem_wen = idu_data.mem_wen;
  assign dispatch_info.reg_wen = idu_data.reg_wen;
  assign dispatch_info.has_old_map = has_old_map;
  assign dispatch_info.old_index = old_index;
  assign dispatch_info.need_rs = idu_data.need_rs;
  assign dispatch_info.rs_valid[0] = rs_valid[0];
  assign dispatch_info.rs_valid[1] = rs_valid[1];
  assign dispatch_info.reg_rinfo.rs1 = rs1;
  assign dispatch_info.reg_rinfo.rs2 = rs2;
  assign dispatch_info.reg_rinfo.rs_zero = rs_zero;
  assign dispatch_info.quit = idu_data.quit;
  assign dispatch_info.is_lsu = idu_data.is_lsu;
  assign dispatch_info.bp_info = idu_data.bp_info;
`ifdef CONFIG_SIM
  always_comb begin
    for (int i = 0; i < 32; i++) o_rat[i] = arat[i];
  end
`endif
endmodule
