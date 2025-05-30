interface if_branch_ctrl();
  logic fencei;
  logic predict_err;
  logic btb_update;
  logic flush;
  logic fencei_fin;

  modport out(output fencei, predict_err, btb_update, flush, fencei_fin);
  modport in(input fencei, predict_err, btb_update, flush, fencei_fin);
endinterface
