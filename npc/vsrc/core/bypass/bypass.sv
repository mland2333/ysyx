module ysyx_24110006_BYPASS(
  input bypass::src_loction_t loc,
  input rf::rdata_t reg_rdata,
  input [31:0] int_result,
  input [31:0] lsu_result,
  output bypass::src_t src
);

assign src.r1 = loc.loc[0] == bypass::from_lsu ? lsu_result : loc.loc[0] == bypass::from_reg ? reg_rdata.r1 : loc.loc[0] == bypass::from_int ? int_result : 0;
assign src.r2 = loc.loc[1] == bypass::from_lsu ? lsu_result : loc.loc[1] == bypass::from_reg ? reg_rdata.r2 : loc.loc[1] == bypass::from_int ? int_result : 0;

endmodule
