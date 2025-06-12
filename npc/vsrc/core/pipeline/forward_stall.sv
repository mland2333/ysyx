`include "common_config.sv"
module ysyx_24110006_FORWARD_STALL (
    input i_valid,
    input [6:0] i_op,
    input [`REG_NUM_INDEX-1:0] i_rs1,
    i_rs2,
`ifdef CONFIG_RENAME
    input [1:0] vrs_zero,
`endif
    input [31:0] i_reg_src1,
    input [31:0] i_reg_src2,
    input [31:0] i_lsu_data,
    input [31:0] i_exu_data,
    input [31:0] i_bru_data,
    input i_exu2bru_valid,
    input i_exu2lsu_valid,
    input i_lsu_valid,
    input i_bru_valid,
    input i_lsu_ready,
    input [`REG_NUM_INDEX-1:0] i_exu2bru_rd,
    input [`REG_NUM_INDEX-1:0] i_exu2lsu_rd,
    input [`REG_NUM_INDEX-1:0] i_lsu_rd,
    input [`REG_NUM_INDEX-1:0] i_bru_rd,
    input i_exu2bru_wen,
    input i_exu2lsu_wen,
    input i_lsu_wen,
    input i_bru_wen,
    output [31:0] o_src1,
    output [31:0] o_src2,
    output o_stall
);

  wire [6:0] op = i_op;
  wire [`REG_NUM_INDEX-1:0] rs1 = i_rs1;
  wire [`REG_NUM_INDEX-1:0] rs2 = i_rs2;

  wire I = op[6:2] == 5'b00100;
  wire R = op[6:2] == 5'b01100;
  wire L = op[6:2] == 5'b00000;
  wire S = op[6:2] == 5'b01000;
  wire JAL = op[6:2] == 5'b11011;
  wire JALR = op[6:2] == 5'b11001;
  wire AUIPC = op[6:2] == 5'b00101;
  wire LUI = op[6:2] == 5'b01101;
  wire B = op[6:2] == 5'b11000;
  wire CSR = op[6:2] == 5'b11100;
  wire FENCE = op[6:2] == 5'b00011;
  wire exu2lsu_rd_active = i_exu2lsu_valid;
  wire lsu_rd_active = !i_lsu_ready;
  wire bru_rd_active = i_bru_valid;
`ifdef CONFIG_RENAME
  wire rs1_exu_forward = !vrs_zero[0] && (rs1 == i_exu2bru_rd && i_exu2bru_wen && i_exu2bru_valid);
  wire rs1_lsu_forward = !vrs_zero[0] && (rs1 == i_lsu_rd && i_lsu_wen && i_lsu_valid);
  wire rs1_bru_forward = !vrs_zero[0] && (rs1 == i_bru_rd && i_bru_wen && i_bru_valid);
  wire rs2_exu_forward = !vrs_zero[1] && (rs2 == i_exu2bru_rd && i_exu2bru_wen && i_exu2bru_valid);
  wire rs2_lsu_forward = !vrs_zero[1] && (rs2 == i_lsu_rd && i_lsu_wen && i_lsu_valid);
  wire rs2_bru_forward = !vrs_zero[1] && (rs2 == i_bru_rd && i_bru_wen && i_bru_valid);
`else
  wire rs1_exu_forward = rs1 != 0 && (rs1 == i_exu2bru_rd && i_exu2bru_wen && i_exu2bru_valid);
  wire rs1_lsu_forward = rs1 != 0 && (rs1 == i_lsu_rd && i_lsu_wen && i_lsu_valid);
  wire rs1_bru_forward = rs1 != 0 && (rs1 == i_bru_rd && i_bru_wen && i_bru_valid);
  wire rs2_exu_forward = rs2 != 0 && (rs2 == i_exu2bru_rd && i_exu2bru_wen && i_exu2bru_valid);
  wire rs2_lsu_forward = rs2 != 0 && (rs2 == i_lsu_rd && i_lsu_wen && i_lsu_valid);
  wire rs2_bru_forward = rs2 != 0 && (rs2 == i_bru_rd && i_bru_wen && i_bru_valid);
`endif
  assign o_src1 = rs1_exu_forward ? i_exu_data : rs1_lsu_forward ? i_lsu_data : rs1_bru_forward ? i_bru_data : i_reg_src1;
  assign o_src2 = rs2_exu_forward ? i_exu_data : rs2_lsu_forward ? i_lsu_data : rs2_bru_forward ? i_bru_data : i_reg_src2;
`ifdef CONFIG_RENAME
  wire rs1_exu_stall = !vrs_zero[0] && (rs1 == i_exu2lsu_rd && i_exu2lsu_wen && exu2lsu_rd_active);
  wire rs1_lsu_stall = !vrs_zero[0] && (rs1 == i_lsu_rd && i_lsu_wen && lsu_rd_active);
  wire rs2_exu_stall = !vrs_zero[1] && (rs2 == i_exu2lsu_rd && i_exu2lsu_wen && exu2lsu_rd_active);
  wire rs2_lsu_stall = !vrs_zero[1] && (rs2 == i_lsu_rd && i_lsu_wen && lsu_rd_active);
`else
  wire rs1_exu_stall = rs1 != 0 && (rs1 == i_exu2lsu_rd && i_exu2lsu_wen && exu2lsu_rd_active);
  wire rs1_lsu_stall = rs1 != 0 && (rs1 == i_lsu_rd && i_lsu_wen && lsu_rd_active);
  wire rs2_exu_stall = rs2 != 0 && (rs2 == i_exu2lsu_rd && i_exu2lsu_wen && exu2lsu_rd_active);
  wire rs2_lsu_stall = rs2 != 0 && (rs2 == i_lsu_rd && i_lsu_wen && lsu_rd_active);
`endif
  wire rs1_stall = rs1_exu_stall || rs1_lsu_stall;
  wire rs2_stall = rs2_exu_stall || rs2_lsu_stall;

  wire stall = rs1_stall || rs2_stall;
  assign o_stall = !(AUIPC||LUI||JAL) && ((JALR||I||L||CSR)&&rs1_stall || (B||S||R)&&stall) && i_valid;

endmodule
