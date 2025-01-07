module ysyx_24110006_IMM(
  input [31:0] i_inst,
  output [31:0] o_imm
);

wire is_i = i_inst[6:0] == 7'b0010011 || i_inst[6:0] == 7'b1100111 || i_inst[6:0] == 7'b0000011 || i_inst[6:0] == 7'b1110011 && i_inst[31:12] != 20'b00110000001000000000;
wire is_u = i_inst[6:0] == 7'b0110111 || i_inst[6:0] == 7'b0010111;
wire is_j = i_inst[6:0] == 7'b1101111;
wire is_s = i_inst[6:0] == 7'b0100011;
wire is_b = i_inst[6:0] == 7'b1100011;
wire is_r = i_inst[6:0] == 7'b0110011;
wire [31:0] immi = {{20{i_inst[31]}}, i_inst[31:20]};
wire [31:0] immu = {i_inst[31:12], 12'b0};
wire [31:0] immj = {{11{i_inst[31]}}, i_inst[31], i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0};
wire [31:0] imms = {{20{i_inst[31]}}, i_inst[31:25], i_inst[11:7]};
wire [31:0] immb = {{19{i_inst[31]}}, i_inst[31], i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0};
wire [31:0] immr = {25'b0, i_inst[31:25]};

assign o_imm = is_i ? immi : is_j ? immj : is_u ? immu : is_s ? imms : is_b ? immb : is_r ? immr : 0;

endmodule
