`include "common_config.sv"
module ysyx_24110006_RegisterFile #(
    DATA_WIDTH = 32
) (
    input i_clock,
    input i_reset,
    input rf::rinfo_t rinfo1, rinfo2,
    output rf::rdata_t rdata1, rdata2,
    input rf::winfo_t winfo1, winfo2
`ifdef CONFIG_SIM
    ,input logic [31:0][5:0] i_rat
`endif
);
  rf::data reg_file[`PREG_NUM];
  always @(posedge i_clock) begin
    for(int i = 0; i<`PREG_NUM; i++)begin
      if(winfo1.valid && winfo1.wen && winfo1.rd == i) reg_file[i] <= winfo1.wdata;
      else if(winfo2.valid && winfo2.wen && winfo2.rd == i) reg_file[i] <= winfo2.wdata;
    end
  end

  assign rdata1.r1 = rinfo1.rs_zero[0] ? 0 : reg_file[rinfo1.rs1];
  assign rdata1.r2 = rinfo1.rs_zero[1] ? 0 : reg_file[rinfo1.rs2];
  assign rdata2.r1 = rinfo2.rs_zero[0] ? 0 : reg_file[rinfo2.rs1];
  assign rdata2.r2 = rinfo2.rs_zero[1] ? 0 : reg_file[rinfo2.rs2];
`ifdef CONFIG_SIM
  reg [DATA_WIDTH-1:0] sim_rf[32];
  always_comb begin
    for (int i = 0; i < 32; i++) sim_rf[i] = reg_file[i_rat[i]];
  end
`endif
endmodule
