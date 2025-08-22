module ysyx_24110006_DISPATCH (
    if_pipeline_vr.in vr_in,
    if_pipeline_vr.out vr_load,
    if_pipeline_vr.out vr_store,
    if_pipeline_vr.out vr_int[2],
    if_pipeline_vr.out vr_rob,
    output store_prior,
    input ooo::dispatch_info_t dispatch_info,
    output ooo::dispatch_inst_t dispatch_int[2],
    output ooo::dispatch_inst_t dispatch_load,
    output ooo::dispatch_inst_t dispatch_store,
    output rob::info_t rob_info,
    input rob::wb_index rob_index[2],
    output rob::wb_index rob_int[2],
    rob_load,
    rob_store
);
  ooo::dispatch_inst_t inst[2];
  always_comb begin
    for (int i = 0; i < 2; i++) begin
      inst[i].basic_inst_info = dispatch_info.d[i].basic_inst_info;
      inst[i].reg_rinfo = dispatch_info.d[i].reg_rinfo;
      inst[i].need_rs = dispatch_info.d[i].need_rs;
      inst[i].rs_valid = dispatch_info.d[i].rs_valid;
      inst[i].mem_wen = dispatch_info.d[i].mem_wen;
      inst[i].reg_wen = dispatch_info.d[i].reg_wen;
      inst[i].rd = dispatch_info.d[i].prd;
      inst[i].vrd = dispatch_info.d[i].vrd;
      inst[i].bp_info = dispatch_info.d[i].bp_info;
    end
  end
  assign store_prior = dispatch_info.d[0].is_lsu && dispatch_info.d[0].mem_wen;
  assign dispatch_load = dispatch_info.d[0].is_lsu && !dispatch_info.d[0].mem_wen ? inst[0] : inst[1];
  assign dispatch_store = dispatch_info.d[0].is_lsu && dispatch_info.d[0].mem_wen ? inst[0] : inst[1];
  logic [1:0] has_int;
  logic has_load, has_store;
  assign has_int[0] = dispatch_info.inst_valid[0] && !dispatch_info.d[0].is_lsu;
  assign has_int[1] = dispatch_info.inst_valid[1] && !dispatch_info.d[1].is_lsu;
  assign has_load = dispatch_info.inst_valid[0] && dispatch_info.d[0].is_lsu && !dispatch_info.d[0].mem_wen ||
          dispatch_info.inst_valid[1] && dispatch_info.d[1].is_lsu && !dispatch_info.d[1].mem_wen;
  assign has_store = dispatch_info.inst_valid[0] && dispatch_info.d[0].is_lsu && dispatch_info.d[0].mem_wen ||
          dispatch_info.inst_valid[1] && dispatch_info.d[1].is_lsu && dispatch_info.d[1].mem_wen;

  assign dispatch_int[0] = inst[0];
  assign dispatch_int[1] = inst[1];
  always_comb begin
    for (int i = 0; i < 2; i++) begin
      rob_info.d[i].pc = dispatch_info.d[i].basic_inst_info.pc;
      rob_info.d[i].reg_wen = dispatch_info.d[i].reg_wen;
      rob_info.d[i].prd = dispatch_info.d[i].prd;
      rob_info.d[i].vrd = dispatch_info.d[i].vrd;
      rob_info.d[i].has_old_map = dispatch_info.d[i].has_old_map;
      rob_info.d[i].old_index = dispatch_info.d[i].old_index;
      rob_info.d[i].quit = dispatch_info.d[i].quit;
      rob_info.d[i].type_store = dispatch_info.d[i].mem_wen;
    end
  end
  assign rob_info.inst_valid = dispatch_info.inst_valid;

  logic load_ready, store_ready;
  logic [1:0] int_ready;
  assign load_ready = has_load && vr_load.ready || !has_load;
  assign store_ready = has_store && vr_store.ready || !has_store;
  assign int_ready[0] = has_int[0] && vr_int[0].ready || !has_int[0];
  assign int_ready[1] = has_int[1] && vr_int[1].ready || !has_int[1];
  assign vr_in.ready = load_ready && store_ready && int_ready[0] && int_ready[1] && vr_rob.ready;

  assign vr_int[0].valid = vr_in.valid && vr_in.ready && has_int[0];
  assign vr_int[1].valid = vr_in.valid && vr_in.ready && has_int[1];
  assign vr_load.valid = vr_in.valid && vr_in.ready && has_load;
  assign vr_store.valid = vr_in.valid && vr_in.ready && has_store;
  assign vr_rob.valid = vr_in.valid && vr_in.ready;

  assign rob_int[0] = rob_index[0];
  assign rob_int[1] = rob_index[1];
  assign rob_load = dispatch_info.inst_valid[0] && dispatch_info.d[0].is_lsu && !dispatch_info.d[0].mem_wen ? rob_index[0] : rob_index[1];
  assign rob_store = dispatch_info.inst_valid[0] && dispatch_info.d[0].is_lsu && dispatch_info.d[0].mem_wen ? rob_index[0] : rob_index[1];
endmodule
