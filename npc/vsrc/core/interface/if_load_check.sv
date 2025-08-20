interface if_load_check ();
  logic [31:0] addr;
  rob::wb_index store_index;
  logic [2:0] read_t;
  logic [31:0] data;
  logic hit, stall;
  modport in(input addr, store_index, read_t, output data, hit, stall);
  modport out(output addr, store_index, read_t, input data, hit, stall);
endinterface
