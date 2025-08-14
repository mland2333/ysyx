module DOUBLE_PROT_FIFO #(
    WIDTH = 8,
    NUM   = 4
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input [1:0] pop_valid,
    [1:0] push_valid,
    input [WIDTH-1:0] data_in1,
    data_in2,
    output [WIDTH-1:0] data_out1,
    data_out2,
    output empty,
    full,
    almost_full
);
  logic [NUM/2-1:0][WIDTH-1:0] fifo1;
  logic [NUM/2-1:0][WIDTH-1:0] fifo2;
  localparam INDEX = $clog2(NUM);
  logic [INDEX-2:0] w_ptr, r_ptr;
  logic [INDEX:0] count;
  logic pop, push;
  assign pop = !(pop_valid == 0);
  assign push = !(push_valid == 0);
  logic r_prior, w_prior; //priority
  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush) w_prior <= 0;
    else if(push && push_valid != 2'b11)
      w_prior <= ~w_prior;
  end
  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush) r_prior <= 0;
    else if(pop && pop_valid != 2'b11)
      r_prior <= ~r_prior;
  end

  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) count <= 0;
    else if (pop && push) begin
      count <= pop_valid == push_valid ? count : pop_valid == 2'b11 ? count - 1 : count + 1;
    end else if (pop) begin
      count <= pop_valid == 2'b11 ? count - 2 : count - 1;
    end else if (push) begin
      count <= push_valid == 2'b11 ? count + 2 : count + 1;
    end
  end

  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush) w_ptr <= 0;
    else if(push) begin
      if(push_valid == 2'b11 || w_prior) w_ptr <= w_ptr + 1;
    end
  end
  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush) r_ptr <= 0;
    else if(pop) begin
      if(pop_valid == 2'b11 || r_prior) r_ptr <= r_ptr + 1;
    end
  end
  assign empty = count == 0;
  assign full = count == NUM;
  assign almost_full = count == NUM-1;
  assign data_out1 = r_prior ? fifo2[r_ptr] : fifo1[r_ptr];
  assign data_out2 = r_prior ? fifo1[r_ptr] : fifo2[r_ptr];
  logic [INDEX-2:0] w_ptr_2;
  assign w_ptr_2 = w_ptr + 1;
  always_ff @(posedge i_clock) begin
    if (push && !i_reset && !i_flush) begin
      if(w_prior && push_valid==2'b11) fifo1[w_ptr_2] <= data_in2;
      else if(!w_prior) fifo1[w_ptr] <= data_in1;
    end
  end
  always_ff @(posedge i_clock) begin
    if (push && !i_reset && !i_flush) begin
      if(w_prior) fifo2[w_ptr] <= data_in1;
      else if(!w_prior && push_valid==2'b11) fifo2[w_ptr] <= data_in2;
    end
  end
endmodule
