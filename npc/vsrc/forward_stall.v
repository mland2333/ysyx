`ifdef CONFIG_FORWARD
module ysyx_24110006_FORWARD_STALL(
  input i_valid,
  input [6:0] i_op,
  input [4:0] i_rs1, i_rs2,
  input [31:0] i_reg_src1,
  input [31:0] i_reg_src2,
  input [31:0] i_lsu_data,
  input [31:0] i_exu_data,
  input i_exu_load,
  input i_lsu_load,
  input i_exu_valid,
  input i_lsu_valid,
  input i_lsu_ready,
  input [4:0] i_exu_rd,
  input [4:0] i_lsu_rd,
  input i_exu_wen, 
  input i_lsu_wen,
  output [31:0] o_src1,
  output [31:0] o_src2,
  output o_stall
);

wire [6:0] op = i_op;
wire [4:0] rs1 = i_rs1;
wire [4:0] rs2 = i_rs2;

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
wire exu_rd_active = i_exu_valid;
wire lsu_rd_active = !i_lsu_ready;
wire rs1_exu_forward = rs1 != 0 && (rs1 == i_exu_rd && i_exu_wen && i_exu_valid && !i_exu_load);
wire rs1_lsu_forward = rs1 != 0 && (rs1 == i_lsu_rd && i_lsu_wen && i_lsu_valid);
wire rs2_exu_forward = rs2 != 0 && (rs2 == i_exu_rd && i_exu_wen && i_exu_valid && !i_exu_load);
wire rs2_lsu_forward = rs2 != 0 && (rs2 == i_lsu_rd && i_lsu_wen && i_lsu_valid);
assign o_src1 = rs1_exu_forward ? i_exu_data : rs1_lsu_forward ? i_lsu_data : i_reg_src1;
assign o_src2 = rs2_exu_forward ? i_exu_data : rs2_lsu_forward ? i_lsu_data : i_reg_src2;

wire rs1_exu_stall = rs1 != 0 && (rs1 == i_exu_rd && i_exu_wen && exu_rd_active && i_exu_load);
wire rs1_lsu_stall = rs1 != 0 && (rs1 == i_lsu_rd && i_lsu_wen && lsu_rd_active && i_lsu_load);
wire rs2_exu_stall = rs2 != 0 && (rs2 == i_exu_rd && i_exu_wen && exu_rd_active && i_exu_load);
wire rs2_lsu_stall = rs2 != 0 && (rs2 == i_lsu_rd && i_lsu_wen && lsu_rd_active && i_lsu_load);

wire rs1_stall = rs1_exu_stall || rs1_lsu_stall;
wire rs2_stall = rs2_exu_stall || rs2_lsu_stall;

wire stall = rs1_stall || rs2_stall;
assign o_stall = !(AUIPC||LUI||JAL) && ((JALR||I||L||CSR)&&rs1_stall || (B||S||R)&&stall) && i_valid;

endmodule
`else 
module ysyx_24110006_STALL(
  input i_valid,
  input [6:0] i_op,
  input [4:0] i_rs1, i_rs2,
  input [4:0] i_exu_rd,
              i_lsu_rd,
  input i_exu_wen, 
        i_lsu_wen,
  input i_exu_valid,
        i_lsu_valid,
        i_lsu_ready,
  output o_stall
);
wire [6:0] op = i_op;
wire [4:0] rs1 = i_rs1;
wire [4:0] rs2 = i_rs2;

wire I = op == 7'b0010011;
wire R = op == 7'b0110011;
wire L = op == 7'b0000011;
wire S = op == 7'b0100011;
wire JAL = op == 7'b1101111;
wire JALR = op == 7'b1100111;
wire AUIPC = op == 7'b0010111;
wire LUI = op == 7'b0110111;
wire B = op == 7'b1100011;
wire CSR = op == 7'b1110011;
wire FENCE = op == 7'b0001111;
wire exu_rd_active = i_exu_valid;
wire lsu_rd_active = !i_lsu_ready || i_lsu_valid;
wire rs1_stall = rs1 != 0 && (rs1 == i_exu_rd && i_exu_wen && exu_rd_active ||
                    rs1 == i_lsu_rd && i_lsu_wen && lsu_rd_active);
wire rs2_stall = rs2 != 0 && (rs2 == i_exu_rd && i_exu_wen && exu_rd_active ||
                    rs2 == i_lsu_rd && i_lsu_wen && lsu_rd_active );
wire stall = rs1_stall || rs2_stall;
assign o_stall = !(AUIPC||LUI||JAL) && ((JALR||I||L||CSR)&&rs1_stall || (B||S||R)&&stall) && i_valid;
endmodule
`endif
