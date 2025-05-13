module ysyx_24110006_WBU (
    input [31:0] i_bru_result,
    i_lsu_result,
    output [31:0] o_result,
    input [31:0] i_bru_pc,
    i_lsu_pc,
    output [31:0] o_pc,
    input i_bru_reg_wen,
    i_lsu_reg_wen,
    output o_reg_wen,
    input [4:0] i_bru_rd,
    i_lsu_rd,
    output [4:0] o_rd,
    input [3:0] i_bru_mcause,
    i_lsu_mcause,
    output [3:0] o_mcause,
    input i_bru_exception,
    i_lsu_exception,
    output o_exception,
`ifdef CONFIG_SIM
    input [6:0] i_bru_op,
    i_lsu_op,
    output [6:0] o_op,
`endif
    if_pipeline_vr.in i_vr_bru,
    if_pipeline_vr.in i_vr_lsu,
    output o_valid
);
assign i_vr_bru.ready = 1;
assign i_vr_lsu.ready = 1;

assign o_valid = i_vr_bru.valid || i_vr_lsu.valid;
assign o_result = i_vr_bru.valid ? i_bru_result : i_lsu_result;
assign o_rd = i_vr_bru.valid ? i_bru_rd : i_lsu_rd;
assign o_reg_wen = i_vr_bru.valid ? i_bru_reg_wen : i_lsu_reg_wen;
assign o_mcause = i_vr_bru.valid ? i_bru_mcause : i_lsu_mcause;
assign o_exception = i_vr_bru.valid ? i_bru_exception : i_lsu_exception;
assign o_pc = i_vr_bru.valid ? i_bru_pc : i_lsu_pc;
assign o_op = i_vr_bru.valid ? i_bru_op : i_lsu_op;
endmodule
