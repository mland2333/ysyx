interface if_load_check ();
  logic [31:0] addr;
  logic [31:0] data;
  logic hit;
  modport in(input addr, output data, hit);
  modport out(output addr, input data, hit);
endinterface
