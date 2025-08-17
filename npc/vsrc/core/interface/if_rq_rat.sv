interface if_rq_rat #();
  rf::vreg [1:0] vrs;
  rf::vreg vrd;
  rf::preg [1:0] prs;
  rf::preg prd;
  logic valid;
  logic [1:0] rs_valid;
  logic has_old_map;
  rf::preg old_index;
  modport in(input vrs, vrd, valid, prd, output prs, rs_valid, has_old_map, old_index);
  modport out(output vrs, vrd, valid, prd, input prs, rs_valid, has_old_map, old_index);
endinterface
