`include "common_config.sv"
module ysyx_24110006_RegisterFile #(
    DATA_WIDTH = 32
) (
    input i_clock,
    input i_reset,
    input pipe::reg_rinfo_t rinfo1,
    output pipe::reg_rdata_t rdata1,
    input pipe::reg_rinfo_t rinfo2,
    output pipe::reg_rdata_t rdata2,
    input pipe::reg_winfo_t winfo,
`ifdef CONFIG_SIM
    input logic [31:0][5:0] i_rat,
`endif
    output reg o_valid
);
  reg [DATA_WIDTH-1:0] rf[`PREG_NUM];
  always @(posedge i_clock) begin
    if (i_reset) rf[0] <= 0;
    else if (winfo.valid && winfo.wen) rf[winfo.rd] <= winfo.wdata;
  end

  always @(posedge i_clock) begin
    if (i_reset) o_valid <= 0;
    else if (winfo.valid) o_valid <= 1;
    else if (o_valid) o_valid <= 0;
  end
  assign rdata1.r1 = rinfo1.rs_zero[0] ? 0 : rf[rinfo1.rs1];
  assign rdata1.r2 = rinfo1.rs_zero[1] ? 0 : rf[rinfo1.rs2];
  assign rdata2.r1 = rinfo2.rs_zero[0] ? 0 : rf[rinfo2.rs1];
  assign rdata2.r2 = rinfo2.rs_zero[1] ? 0 : rf[rinfo2.rs2];
`ifdef CONFIG_SIM
  always_comb begin
    for (int i = 0; i < `PREG_NUM; i++) $dumpvars(0, rf[i]);
  end
  reg [DATA_WIDTH-1:0] sim_rf[32];
  always_comb begin
    for (int i = 0; i < 32; i++) sim_rf[i] = rf[i_rat[i]];
  end
`endif
endmodule
