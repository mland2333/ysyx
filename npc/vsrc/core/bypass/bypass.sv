module ysyx_24110006_BYPASS(
  input bypass::src_loction_t loc,
  input rf::rdata_t reg_rdata,
  input [31:0] int_result,
  input [31:0] lsu_result,
  output bypass::src_t src
);

assign src.d[0] = {32{(loc.loc[0][bypass::from_int])}} & int_result |
                  {32{(loc.loc[0][bypass::from_lsu])}} & lsu_result |
                  {32{(loc.loc[0][bypass::from_reg])}} & reg_rdata.d[0];
assign src.d[1] = {32{(loc.loc[1][bypass::from_int])}} & int_result |
                  {32{(loc.loc[1][bypass::from_lsu])}} & lsu_result |
                  {32{(loc.loc[1][bypass::from_reg])}} & reg_rdata.d[1];
endmodule
