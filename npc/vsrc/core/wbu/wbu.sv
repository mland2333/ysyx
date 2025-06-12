module ysyx_24110006_WBU (
    input pipe::wbu_t from_bru,
    input pipe::wbu_t from_lsu,
    input pipe::csr_einfo_t bru_einfo,
    input pipe::csr_einfo_t lsu_einfo,
    output pipe::csr_einfo_t to_csr,
    output pipe::reg_winfo_t reg_winfo,
`ifdef CONFIG_RENAME
    output ooo::retire_info_t retire_info,
`endif
`ifdef CONFIG_SIM
    input pipe::sim_t i_bru_sim, i_lsu_sim,
    output pipe::sim_t o_sim,
`endif
    if_pipeline_vr.in i_vr_bru,
    if_pipeline_vr.in i_vr_lsu,
    output [31:0] o_pc,
    output o_valid
);
  assign i_vr_bru.ready = 1;
  assign i_vr_lsu.ready = 1;
  pipe::wbu_t wbu_data;
  assign o_valid = i_vr_bru.valid || i_vr_lsu.valid;
  assign wbu_data = i_vr_bru.valid ? from_bru : i_vr_lsu.valid ? from_lsu : 0;
  assign to_csr = i_vr_bru.valid ? bru_einfo : i_vr_lsu.valid ? lsu_einfo : 0;
  assign reg_winfo.rd = wbu_data.reg_rd;
  assign reg_winfo.wdata = wbu_data.result;
`ifdef CONFIG_RENAME
  assign reg_winfo.wen = wbu_data.reg_wen && wbu_data.vrd != 0;
`else
  assign reg_winfo.wen = wbu_data.reg_wen;
`endif
`ifdef CONFIG_SIM
  assign o_sim = i_vr_bru.valid ? i_bru_sim : i_vr_lsu.valid ? i_lsu_sim : 0;
`endif
  assign o_pc = wbu_data.pc;
`ifdef CONFIG_RENAME
  assign retire_info.flush_retire = o_valid && wbu_data.is_flush;
  assign retire_info.retire = o_valid && wbu_data.reg_wen && wbu_data.vrd != 0;
  assign retire_info.has_old_map = wbu_data.has_old_map;
  assign retire_info.old_index = wbu_data.old_index;
  assign retire_info.vrd = wbu_data.vrd;
  assign retire_info.prd = wbu_data.reg_rd;
`endif
endmodule
