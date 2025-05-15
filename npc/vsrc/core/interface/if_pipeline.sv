interface if_pipeline_vr();
  logic valid;
  logic ready;
  modport in(
    input valid,
    output ready
  );
  modport out(
    output valid,
    input ready
  );
endinterface
