module FREE_LIST #(
    WIDTH = 8,
    NUM   = 4
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input pop,
    push,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out,
    output empty,
    full
);

  logic [NUM-1:0][WIDTH-1:0] fifo;
  localparam INDEX = $clog2(NUM);
  logic [INDEX-1:0] w_ptr, r_ptr;
  logic [INDEX:0] count;
  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush) begin
      for(int i = 0; i<NUM; i++)begin
        fifo[i] <= (WIDTH)'(i);
      end
    end
    else if(push)begin
      fifo[w_ptr] <= data_in;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) begin
      w_ptr <= 0;
      r_ptr <= 0;
      count <= NUM;
    end else if (pop && push) begin
      w_ptr <= w_ptr + 1;
      r_ptr <= r_ptr + 1;
    end else if (pop) begin
      r_ptr <= r_ptr + 1;
      count <= count - 1;
    end else if (push) begin
      w_ptr <= w_ptr + 1;
      count <= count + 1;
    end
  end

  assign empty = count == 0;
  assign full = count == NUM;
  assign data_out = fifo[r_ptr];

endmodule
