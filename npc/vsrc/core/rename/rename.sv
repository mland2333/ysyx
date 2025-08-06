module ysyx_24110006_RENAME #(
    parameter PREG_NUM = 64
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input ooo::retire_info_t retire_info,
    input ooo::idu2rename_t from_idu,
    output ooo::dispatch_info_t dispatch_info,
`ifdef CONFIG_SIM
    output logic [31:0][5:0] o_rat,
`endif
    if_pipeline_vr i_vr,
    if_pipeline_vr o_vr
);
  logic r_valid;
  assign r_valid = i_vr.valid & ~in_flush;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) o_vr.valid <= 0;
    else if (r_ready && r_valid && !o_vr.valid) begin
      o_vr.valid <= 1;
    end else if (!r_ready && o_vr.valid && o_vr.ready && !i_vr.valid) begin
      o_vr.valid <= 0;
    end
  end
  reg r_ready;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) r_ready <= 1;
    else if (r_ready && r_valid && !o_vr.valid) r_ready <= 0;
    else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) r_ready <= 1;
  end
  assign i_vr.ready = (r_ready | o_vr.ready) & ~in_flush;
  logic update_reg;
  assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush && !in_flush;

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
  assign need_alloc = r_valid && from_idu.reg_wen && i_vr.ready && from_idu.vrd != 0 && !in_flush && !i_flush;
  always_ff @(posedge i_clock) begin
    flush_retire <= retire_info.flush_retire;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) in_flush <= 0;
    else if (i_flush && !retire_info.flush_retire) in_flush <= 1;
    else if (in_flush && flush_retire) in_flush <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      free_list.r_ptr <= 0;
      free_list.w_ptr <= (PREG_NUM_INDEX)'(PREG_NUM - 1);
      free_list.count <= PREG_NUM;
    end else if (flush_retire) begin
      free_list.r_ptr <= free_list_backup.r_ptr;
      free_list.w_ptr <= free_list_backup.w_ptr;
      free_list.count <= free_list_backup.count;
    end else begin
      if (need_alloc && retire_info.retire && retire_info.has_old_map) begin
        free_list.w_ptr <= free_list.w_ptr + 1;
        free_list.r_ptr <= free_list.r_ptr + 1;
      end else if (retire_info.retire && !empty && retire_info.has_old_map) begin
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
      free_list_backup.w_ptr <= (PREG_NUM_INDEX)'(PREG_NUM - 1);
      free_list_backup.count <= PREG_NUM;
    end else begin
      if (retire_info.retire) begin
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
    else if (retire_info.retire && !full && retire_info.has_old_map)
      free_list.preg_index[free_list.w_ptr] <= retire_info.old_index;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < PREG_NUM; i++) free_list_backup.preg_index[i] <= (PREG_NUM_INDEX)'(i);
    end else if (retire_info.retire && retire_info.has_old_map)
      free_list_backup.preg_index[free_list_backup.w_ptr] <= retire_info.old_index;
  end

  ooo::idu2rename_t idu_data;
  always_ff @(posedge i_clock) begin
    if (update_reg) idu_data <= from_idu;
  end

  logic [PREG_NUM_INDEX-1:0] rat [32];
  logic [PREG_NUM_INDEX-1:0] arat[32];
  typedef enum {
    IDLE,
    MAPPED,
    ZERO,
    READY
  } reg_state_t;
  reg_state_t reg_state[32], areg_state[32];
  always_ff @(posedge i_clock) begin
    for(int i = 0; i<32; i++) begin
      if (i_reset) reg_state[i] <= IDLE;
      else if (flush_retire) begin
      reg_state[i] <= areg_state[i];
      end else begin
        if (need_alloc && !full && from_idu.vrd != 0 && from_idu.vrd == i) reg_state[i] <= MAPPED;
        else if (retire_info.retire && retire_info.prd == rat[retire_info.vrd] && retire_info.vrd == i)
          reg_state[i] <= READY;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < 32; i++) areg_state[i] <= IDLE;
    end else begin
      if (retire_info.retire) areg_state[retire_info.vrd] <= READY;
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
    end else if (retire_info.retire) begin
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
      rs_valid[0] <= reg_state[from_idu.vrs1] != MAPPED || from_idu.vrs1 == 0 || retire_info.retire && retire_info.prd == rat[from_idu.vrs1];
      rs_valid[1] <= reg_state[from_idu.vrs2] != MAPPED || from_idu.vrs2 == 0 || retire_info.retire && retire_info.prd == rat[from_idu.vrs2];
    end
  end
  /* logic [1:0] reg_ready; */
  /* always_ff@(posedge i_clock)begin */
  /*   if(update_reg)begin */
  /*     reg_ready[0] <= retire_info.retire && retire_info.vrd == from_idu.vrs1; */
  /*     reg_ready[1] <= retire_info.retire && retire_info.vrd == from_idu.vrs2; */
  /*   end */
  /* end */

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
`ifdef CONFIG_SIM
  always_comb begin
    for (int i = 0; i < 32; i++) o_rat[i] = arat[i];
  end
`endif
endmodule
