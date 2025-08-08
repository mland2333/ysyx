module ysyx_24110006_DISPATCH (
    if_pipeline_vr.in vr_in,
    if_pipeline_vr.out vr_lsu,
    if_pipeline_vr.out vr_int,
    if_pipeline_vr.out vr_rob,
    input ooo::dispatch_info_t dispatch_info,
    output ooo::dispatch_inst_t dispatch_int,
    output ooo::dispatch_inst_t dispatch_lsu,
    output rob::inst_info_t rob_info
);
  assign dispatch_int.basic_inst_info = dispatch_info.basic_inst_info;
  assign dispatch_int.reg_rinfo = dispatch_info.reg_rinfo;
  assign dispatch_int.need_rs = dispatch_info.need_rs;
  assign dispatch_int.rs_valid = dispatch_info.rs_valid;
  assign dispatch_int.reg_wen = dispatch_info.reg_wen;
  assign dispatch_int.rd = dispatch_info.prd;
  assign dispatch_int.vrd = dispatch_info.vrd;

  assign dispatch_lsu.basic_inst_info = dispatch_info.basic_inst_info;
  assign dispatch_lsu.reg_rinfo = dispatch_info.reg_rinfo;
  assign dispatch_lsu.need_rs = dispatch_info.need_rs;
  assign dispatch_lsu.rs_valid = dispatch_info.rs_valid;
  assign dispatch_lsu.mem_wen = dispatch_info.mem_wen;
  assign dispatch_lsu.reg_wen = dispatch_info.reg_wen;
  assign dispatch_lsu.rd = dispatch_info.prd;
  assign dispatch_lsu.vrd = dispatch_info.vrd;

  assign rob_info.pc = dispatch_info.basic_inst_info.pc;
  assign rob_info.reg_wen = dispatch_info.reg_wen;
  assign rob_info.prd = dispatch_info.prd;
  assign rob_info.vrd = dispatch_info.vrd;
  assign rob_info.has_old_map = dispatch_info.has_old_map;
  assign rob_info.old_index = dispatch_info.old_index;
  assign rob_info.quit = dispatch_info.quit;

  assign vr_in.ready = vr_lsu.ready && vr_int.ready && vr_rob.ready;
  assign vr_int.valid = vr_in.valid && !dispatch_info.is_lsu && vr_rob.ready && vr_lsu.ready;
  assign vr_lsu.valid = vr_in.valid && dispatch_info.is_lsu && vr_rob.ready && vr_int.ready;
  assign vr_rob.valid = vr_in.valid && vr_rob.ready && vr_int.ready && vr_lsu.ready;
endmodule
