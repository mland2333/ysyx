`include "alu_config.sv"
`include "common_config.sv"
module ysyx_24110006_EXU (
    input i_clock,
    input i_reset,
`ifdef CONFIG_RENAME
    input ooo::rename2exu_t from_idu,
`else
    input pipe::idu2exu_t from_idu,
`endif
    input pipe::reg_rdata_t from_reg,
    input pipe::csr_rdata_t from_csr,
    output pipe::exu2bru_t to_bru,
    output pipe::exu2lsu_t to_lsu,
    input alu::op_t from_aluop,
    input i_stall,
    input i_flush,
    output o_flush,
`ifdef CONFIG_SIM
    input pipe::sim_t i_sim,
    output pipe::sim_t o_sim,
`endif
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr
);
`ifdef CONFIG_RENAME
  ooo::rename2exu_t idu_data;
`else
  pipe::idu2exu_t idu_data;
`endif
  pipe::reg_rdata_t reg_data;
  pipe::csr_rdata_t csr_data;
  alu::op_t alu_op;

  always_ff @(posedge i_clock) begin
    if (update_reg) idu_data <= from_idu;
  end
  always_ff @(posedge i_clock) begin
    if (update_reg) reg_data <= from_reg;
  end
  always_ff @(posedge i_clock) begin
    if (update_reg) csr_data <= from_csr;
  end
  always_ff @(posedge i_clock) begin
    if (update_reg) alu_op <= from_aluop;
  end

  reg [31:0] mem_wdata;
  wire update_reg;
  logic r_valid;
  assign r_valid = i_vr.valid & ~i_stall;
  always @(posedge i_clock) begin
    if (i_reset || (i_flush && o_vr.ready)) o_vr.valid <= 0;
    else if (r_ready && r_valid && !o_vr.valid) begin
      o_vr.valid <= 1;
    end else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) begin
      o_vr.valid <= 0;
    end
  end
  reg r_ready;
  always @(posedge i_clock) begin
    if (i_reset || (i_flush && o_vr.ready)) r_ready <= 1;
    else if (r_ready && r_valid && !o_vr.valid) r_ready <= 0;
    else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) r_ready <= 1;
    /* else if (i_stall) r_ready <= 0; */
    /* else if (r_valid && o_vr.valid && (i_wen || i_ren)) r_ready <= 0; */
    /* else if (o_vr.ready) r_ready <= 1; */
    /* else if (r_valid) r_ready <= 0; */
    /* else if (!r_valid && !o_vr.valid) r_ready <= 1; */
  end
  assign i_vr.ready = (r_ready | o_vr.ready) & ~i_stall;
  assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush;
  reg flush_valid;
  always @(posedge i_clock) begin
    if (i_reset) flush_valid <= 0;
    else if (update_reg) flush_valid <= 1;
    else if (flush_valid) flush_valid <= 0;
  end

  /* assign o_flush = (JALR | csr_t[1] | JAL & ~predict) & flush_valid; */
  assign o_flush = (JALR | idu_data.csr_t[1] | JAL) & flush_valid;

  /* assign o_exception = exception; */
  /* assign o_mcause = mcause; */

  reg [31:0] upc;
  always @(posedge i_clock) begin
    if (update_reg)
      upc <= (from_idu.op == 7'b1110011 && from_idu.func == 0) ? from_csr.upc : (from_idu.op == 7'b1100111 ? from_reg.r1 : from_idu.pc);
  end


  /* assign o_btb_update = !predict && JAL && flush_valid; */

  wire I = idu_data.op[6:2] == 5'b00100;
  wire R = idu_data.op[6:2] == 5'b01100;
  wire L = idu_data.op[6:2] == 5'b00000;
  wire S = idu_data.op[6:2] == 5'b01000;
  wire JAL = idu_data.op[6:2] == 5'b11011;
  wire JALR = idu_data.op[6:2] == 5'b11001;
  wire AUIPC = idu_data.op[6:2] == 5'b00101;
  wire LUI = idu_data.op[6:2] == 5'b01101;
  wire B = idu_data.op[6:2] == 5'b11000;
  wire CSR = idu_data.op[6:2] == 5'b11100;
  wire FENCE = idu_data.op[6:2] == 5'b00011;

  wire is_beq = B & f000;
  wire is_bne = B & f001;
  wire is_blt = B & (f100 | f110);
  wire is_bge = B & (f101 | f111);

  wire f000 = idu_data.func == 3'b000;
  wire f001 = idu_data.func == 3'b001;
  wire f010 = idu_data.func == 3'b010;
  wire f011 = idu_data.func == 3'b011;
  wire f100 = idu_data.func == 3'b100;
  wire f101 = idu_data.func == 3'b101;
  wire f110 = idu_data.func == 3'b110;
  wire f111 = idu_data.func == 3'b111;

  alu::result_t alu_result;
  ysyx_24110006_ALU malu (
      .op(alu_op),
      /* .o_zero(zero), */
      .result(alu_result)
  );
  logic [`BRANCH_MID] branch_mid;
  assign branch_mid[`BRANCH] = B;
  assign branch_mid[`BRANCH_BACK] = B & (idu_data.imm[31]);
  assign branch_mid[`ZERO] = reg_data.r1 == reg_data.r2;
  assign branch_mid[`CMP] = alu_result.cmp;
  assign branch_mid[`BEQ] = is_beq;
  assign branch_mid[`BNE] = is_bne;
  assign branch_mid[`BLT] = is_blt;
  assign branch_mid[`BGE] = is_bge;

  assign to_bru.result = CSR ? csr_data.r1 : alu_result.r;
  assign to_bru.reg_wen = !(S || B || FENCE);
  assign to_bru.jump = JAL | JALR | idu_data.csr_t[1];
  assign to_bru.branch_mid = branch_mid;
  assign to_bru.upc = upc + idu_data.imm;
  assign to_bru.csr_t = idu_data.csr_t;
  assign to_bru.csr = idu_data.csr;
  assign to_bru.reg_rd = idu_data.reg_rd;
  assign to_bru.pc = idu_data.pc;
  assign to_bru.exception = idu_data.exception;
  assign to_bru.mcause = idu_data.mcause;
  assign to_bru.csr_wdata = alu_result.r;
  assign to_bru.fencei = FENCE && f001;
  assign to_bru.quit = idu_data.quit;
`ifdef CONFIG_RENAME
  assign to_bru.has_old_map = idu_data.has_old_map;
  assign to_bru.old_index = idu_data.old_index;
  assign to_bru.vrd = idu_data.vrd;
`endif

  assign to_lsu.ren = L;
  assign to_lsu.wen = S;
  assign to_lsu.addr = alu_result.add_r;
  assign to_lsu.wdata = reg_data.r2;
  assign to_lsu.wmask = S ? (f000 ? 4'b0001 : f001 ? 4'b0011 : 4'b1111) : 0;
  assign to_lsu.read_t = L ? idu_data.func : 0;
  assign to_lsu.reg_rd = idu_data.reg_rd;
  assign to_lsu.reg_wen = !(S || B || FENCE);
  assign to_lsu.pc = idu_data.pc;
  assign to_lsu.exception = idu_data.exception;
  assign to_lsu.mcause = idu_data.mcause;
`ifdef CONFIG_RENAME
  assign to_lsu.has_old_map = idu_data.has_old_map;
  assign to_lsu.old_index = idu_data.old_index;
  assign to_lsu.vrd = idu_data.vrd;
`endif
`ifdef CONFIG_SIM
  always_ff @(posedge i_clock) begin
    if (update_reg) o_sim <= i_sim;
  end
`endif
endmodule
