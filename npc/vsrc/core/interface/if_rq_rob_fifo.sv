interface if_rq_rob_fifo #(
    parameter WIDTH = 8,
    parameter NUM = 8
) ();
  localparam INDEX = $clog2(NUM);
  logic push, pop;
  logic [WIDTH-1:0] push_data, pop_data;
  logic [INDEX-1:0] pop_index;
  rob::wb_index push_index;
  modport in(input push, pop, push_data, output pop_data, pop_index, push_index);
  modport out(output push, pop, push_data, input pop_data, pop_index, push_index);
endinterface
