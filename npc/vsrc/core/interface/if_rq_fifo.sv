interface if_rq_fifo #(
    parameter WIDTH = 8
) ();
  logic push, pop;
  logic [WIDTH-1:0] push_data, pop_data;
  modport in(input push, pop, push_data, output pop_data);
  modport out(output push, pop, push_data, input pop_data);
endinterface
