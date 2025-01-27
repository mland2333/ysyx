module ysyx_24110006_STALL(
  input i_valid,
  input [6:0] i_op,
  input [4:0] i_rs1, i_rs2,
  input [4:0] i_exu_rd,
              i_lsu_rd,
  input i_exu_wen, 
        i_lsu_wen,
  input i_exu_busy,
        i_lsu_busy,
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
wire exu_rd_active = i_exu_busy;
wire lsu_rd_active = i_lsu_busy;
wire rs1_stall = rs1 != 0 && (rs1 == i_exu_rd && i_exu_wen && exu_rd_active ||
                    rs1 == i_lsu_rd && i_lsu_wen && lsu_rd_active);
wire rs2_stall = rs2 != 0 && (rs2 == i_exu_rd && i_exu_wen && exu_rd_active ||
                    rs2 == i_lsu_rd && i_lsu_wen && lsu_rd_active );
wire stall = rs1_stall || rs2_stall;
assign o_stall = !(AUIPC||LUI||JAL) && ((JALR||I||L||CSR)&&rs1_stall || (B||S||R)&&stall) && i_valid;


endmodule
