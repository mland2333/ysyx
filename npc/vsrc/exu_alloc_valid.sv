module ysyx_24110006_EXU_ALLOC_VALID (
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr_bru,
    if_pipeline_vr.out o_vr_lsu,
    input i_wen,
    input i_ren
);

  assign o_vr_bru.valid = i_vr.valid && !(i_wen || i_ren) && o_vr_lsu.ready;
  assign o_vr_lsu.valid = i_vr.valid && (i_wen || i_ren);
  assign i_vr.ready = o_vr_lsu.ready && o_vr_bru.ready;


endmodule
