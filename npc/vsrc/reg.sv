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
`ifdef RISCV32E
  `define HIGH_BIT 3
  `define INDEX 3:0
  localparam REG_NUM = 2**4;
`else
  `define HIGH_BIT 4
  `define INDEX 4:0
  localparam REG_NUM = 2**5;
`endif
  reg [DATA_WIDTH-1:0] rf [REG_NUM];
  always @(posedge i_clock) begin
    if (i_valid && i_wen && i_waddr != 0) rf[i_waddr[`INDEX]] <= i_wdata;
  end
  /* always@(posedge i_clock)begin */
  /*   if(i_valid && i_wen && i_waddr != 0)begin */
  /*     integer i; */
  /*     for(i=1; i<16; i=i+1)begin */
  /*       if(i_waddr[3:0]==i) rf[i] <= i_wdata; */
  /*     end */
  /*   end */
  /* end */
  always@(posedge i_clock)begin
    if(i_reset) o_valid <= 0;
    else if(i_valid) o_valid <= 1;
    else if(o_valid) o_valid <= 0;
  end
  logic [31:0] rdata1_low, rdata1_high;
  logic [31:0] rdata2_low, rdata2_high;
  always@(*)begin
    integer i;
    rdata1_low = 0;
    rdata2_low = 0;
    for(i=1; i<REG_NUM/2; i=i+1)begin
      rdata1_low = rdata1_low | ({32{i_raddr1[`INDEX] == i}} & rf[i]);
      rdata2_low = rdata2_low | ({32{i_raddr2[`INDEX] == i}} & rf[i]);
    end
  end
  always@(*)begin
    integer i;
    rdata1_high = 0;
    rdata2_high = 0;
    for(i=REG_NUM/2; i<REG_NUM; i=i+1)begin
      rdata1_high = rdata1_high | ({32{i_raddr1[`INDEX] == i}} & rf[i]);
      rdata2_high = rdata2_high | ({32{i_raddr2[`INDEX] == i}} & rf[i]);
    end
  end
  assign o_rdata1 = i_raddr1[`HIGH_BIT] ? rdata1_high : rdata1_low;
  assign o_rdata2 = i_raddr2[`HIGH_BIT] ? rdata2_high : rdata2_low;
endmodule
