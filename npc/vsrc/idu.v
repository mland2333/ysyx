module ysyx_24110006_IDU(
  input i_clock,
  input i_reset,
  input [31:0] i_inst,
  output [6:0] o_op,
  output [2:0] o_func,
  output [4:0] o_reg_rs1,
  output [4:0] o_reg_rs2,
  output [4:0] o_reg_rd,
  output [31:0] o_imm,
  output [2:0] o_csr_t,

  input i_valid,
  output reg o_valid
);

reg[31:0] inst;

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(!o_valid && i_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    inst <= i_inst;
end

assign o_op = inst[6:0];
assign o_func = inst[14:12];
assign o_reg_rd = inst[11:7];
assign o_reg_rs1 = inst[19:15];
assign o_reg_rs2 = inst[24:20];
wire is_i = inst[6:0] == 7'b0010011 || inst[6:0] == 7'b1100111 || inst[6:0] == 7'b0000011 || inst[6:0] == 7'b1110011;
wire is_u = inst[6:0] == 7'b0110111 || inst[6:0] == 7'b0010111;
wire is_j = inst[6:0] == 7'b1101111;
wire is_s = inst[6:0] == 7'b0100011;
wire is_b = inst[6:0] == 7'b1100011;
wire is_r = inst[6:0] == 7'b0110011;

wire [31:0] immi = {{20{inst[31]}}, inst[31:20]};
wire [31:0] immu = {inst[31:12], 12'b0};
wire [31:0] immj = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
wire [31:0] imms = {{20{inst[31]}}, inst[31:25], inst[11:7]};
wire [31:0] immb = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
wire [31:0] immr = {25'b0, inst[31:25]};

assign o_imm = is_i ? immi : is_j ? immj : is_u ? immu : is_s ? imms : is_b ? immb : immr;

localparam MRET = 3'b000;
localparam CSRW = 3'b001;
localparam ECALL = 3'b011;
assign o_csr_t = o_func == 3'b0 ? (immi[1] ? MRET : ECALL) : CSRW;

endmodule
