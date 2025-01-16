module ysyx_24110006_CONFLICT(
  input i_valid,
  input [6:0] i_op,
  input [4:0] i_rs1, i_rs2,
  input [4:0] i_lsu_rd,
              i_wbu_rd,
  input i_lsu_wen, 
        i_wbu_wen,
  input i_lsu_busy,
        i_wbu_busy,
  output o_conflict
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
wire lsu_rd_active = i_lsu_busy;
wire wbu_rd_active = i_wbu_busy;
wire rs1_conflict = rs1 != 0 && (rs1 == i_lsu_rd && i_lsu_wen && lsu_rd_active ||
                    rs1 == i_wbu_rd && i_wbu_wen && wbu_rd_active);
wire rs2_conflict = rs2 != 0 && (rs2 == i_lsu_rd && i_lsu_wen && lsu_rd_active ||
                    rs2 == i_wbu_rd && i_wbu_wen && wbu_rd_active );
wire conflict = rs1_conflict || rs2_conflict;
assign o_conflict = !(AUIPC||LUI||JAL) && ((JALR||I||L)&&rs1_conflict || (B||S||R)&&conflict) && i_valid;


endmodule
