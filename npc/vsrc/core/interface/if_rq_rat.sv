interface if_rq_rat #(

);
    rf::vreg vrs1, vrs2, vrd;
    rf::preg prs1, prs2, prd;
    logic valid;
    logic [1:0] rs_valid;
    logic has_old_map;
    rf::preg  old_index;
    modport in (
        input vrs1, vrs2, vrd, valid, prd,
        output prs1, prs2, rs_valid, has_old_map, old_index
    );
    modport out (
        output vrs1, vrs2, vrd, valid, prd,
        input prs1, prs2, rs_valid, has_old_map, old_index
    );
endinterface