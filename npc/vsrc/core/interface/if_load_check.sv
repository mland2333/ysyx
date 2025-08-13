interface if_load_check ();
  logic [31:0] addr;
  rob::wb_index store_index;
  logic [31:0] data;
  logic hit;
  modport in(input addr, store_index, output data, hit);
  modport out(output addr, store_index, input data, hit);
endinterface
