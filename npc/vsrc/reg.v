module ysyx_24110006_RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
  input i_clock,
  input [DATA_WIDTH-1:0] i_wdata,
  input [ADDR_WIDTH-1:0] i_waddr,
  input [ADDR_WIDTH-1:0] i_raddr1,
  input [ADDR_WIDTH-1:0] i_raddr2,
  input i_wen,
  output [DATA_WIDTH-1:0] o_rdata1,
  output [DATA_WIDTH-1:0] o_rdata2,

  input i_valid
);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  always @(posedge i_clock) begin
    if (i_valid && i_wen) rf[i_waddr] <= i_wdata;
  end
  assign o_rdata1 = i_raddr1 == 0 ? 0 : rf[i_raddr1];
  assign o_rdata2 = i_raddr2 == 0 ? 0 : rf[i_raddr2];
endmodule
