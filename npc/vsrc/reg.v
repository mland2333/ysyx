module ysyx_24110006_RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
  input i_clock,
  input i_reset,
  input [DATA_WIDTH-1:0] i_wdata,
  input [ADDR_WIDTH-1:0] i_waddr,
  input [ADDR_WIDTH-1:0] i_raddr1,
  input [ADDR_WIDTH-1:0] i_raddr2,
  input i_wen,
  output [DATA_WIDTH-1:0] o_rdata1,
  output [DATA_WIDTH-1:0] o_rdata2,

  input i_valid,
  output reg o_valid
);
  reg [DATA_WIDTH-1:0] rf [2**4-1:0];
  always @(posedge i_clock) begin
    if (i_valid && i_wen) rf[i_waddr[3:0]] <= i_wdata;
  end
  always@(posedge i_clock)begin
    if(i_reset) o_valid <= 0;
    else if(i_valid) o_valid <= 1;
    else if(o_valid) o_valid <= 0;
  end
  assign o_rdata1 = i_raddr1 == 0 ? 0 : rf[i_raddr1[3:0]];
  assign o_rdata2 = i_raddr2 == 0 ? 0 : rf[i_raddr2[3:0]];
endmodule
