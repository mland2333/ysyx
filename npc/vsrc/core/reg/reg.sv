`include "common_config.sv"
module ysyx_24110006_RegisterFile #(DATA_WIDTH = 32) (
  input i_clock,
  input i_reset,
  input pipe::reg_rinfo_t rinfo,
  output pipe::reg_rdata_t rdata,
  input pipe::reg_winfo_t winfo,

  input i_valid,
  output reg o_valid
);
/* `ifdef RISCV32E */
/*   `define HIGH_BIT 3 */
/*   `define INDEX 3:0 */
/*   localparam int REG_NUM = 2**4; */
/* `else */
/*   `define HIGH_BIT 4 */
/*   `define INDEX 4:0 */
/*   localparam int REG_NUM = 2**5; */
/* `endif */
/*   reg [DATA_WIDTH-1:0] rf [REG_NUM]; */
/*   always @(posedge i_clock) begin */
/*     if (i_valid && winfo.wen && winfo.rd != 0) rf[winfo.rd[`INDEX]] <= winfo.wdata; */
/*   end */
/*   always@(posedge i_clock)begin */
/*     if(i_reset) o_valid <= 0; */
/*     else if(i_valid) o_valid <= 1; */
/*     else if(o_valid) o_valid <= 0; */
/*   end */
/*   logic [31:0] rdata1_low, rdata1_high; */
/*   logic [31:0] rdata2_low, rdata2_high; */
/*   logic [4:0] raddr1, raddr2; */
/*   assign raddr1 = rinfo.rs1; */
/*   assign raddr2 = rinfo.rs2; */
/*   always_comb begin */
/*     rdata1_low = 0; */
/*     rdata2_low = 0; */
/*     for(int i=1; i<REG_NUM/2; i++)begin */
/*       rdata1_low = rdata1_low | ({32{raddr1[`INDEX] == i}} & rf[i]); */
/*       rdata2_low = rdata2_low | ({32{raddr2[`INDEX] == i}} & rf[i]); */
/*     end */
/*   end */
/*   always_comb begin */
/*     rdata1_high = 0; */
/*     rdata2_high = 0; */
/*     for(int i=REG_NUM/2; i<REG_NUM; i++)begin */
/*       rdata1_high = rdata1_high | ({32{raddr1[`INDEX] == i}} & rf[i]); */
/*       rdata2_high = rdata2_high | ({32{raddr2[`INDEX] == i}} & rf[i]); */
/*     end */
/*   end */
/*   assign rdata.r1 = raddr1[`HIGH_BIT] ? rdata1_high : rdata1_low; */
/*   assign rdata.r2 = raddr2[`HIGH_BIT] ? rdata2_high : rdata2_low; */
  reg [DATA_WIDTH-1:0] rf [`PREG_NUM];
`ifdef CONFIG_RENAME
  always @(posedge i_clock) begin
    if(i_reset) rf[0] <= 0;
    else if (i_valid && winfo.wen) rf[winfo.rd] <= winfo.wdata;
  end
`else
  always @(posedge i_clock) begin
    if(i_reset) rf[0] <= 0;
    else if (i_valid && winfo.wen && winfo.rd != 0) rf[winfo.rd] <= winfo.wdata;
  end
`endif
  always@(posedge i_clock)begin
    if(i_reset) o_valid <= 0;
    else if(i_valid) o_valid <= 1;
    else if(o_valid) o_valid <= 0;
  end
`ifdef CONFIG_RENAME
  assign rdata.r1 = rinfo.rs_zero[0] ? 0 : rf[rinfo.rs1];
  assign rdata.r2 = rinfo.rs_zero[1] ? 0 : rf[rinfo.rs2];
`else
  assign rdata.r1 = rf[rinfo.rs1];
  assign rdata.r2 = rf[rinfo.rs2];
`endif
/* `ifdef CONFIG_SIM */
/*   logic [31:0] sim_rf[32]; */
/*   `ifdef CONFIG_RENAME */
/*   `else */
/*   `endif */
/* `endif */
endmodule
