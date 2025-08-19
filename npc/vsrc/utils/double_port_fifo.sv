module DOUBLE_PROT_FIFO #(
    WIDTH = 8,
    NUM   = 4
) (
    input i_clock,
    input i_reset,
    input i_flush,
    if_rq_fifo.in rq1,
    rq2,
    output empty,
    almost_empty,
    full,
    almost_full
);
  logic [NUM/2-1:0][WIDTH-1:0] fifo1;
  logic [NUM/2-1:0][WIDTH-1:0] fifo2;
  localparam INDEX = $clog2(NUM);
  logic [INDEX-2:0] w_ptr, r_ptr;
  logic [INDEX:0] count;
  logic pop, push, pop2, push2;
  assign pop   = rq1.pop || rq2.pop;
  assign push  = rq1.push || rq2.push;
  assign pop2  = rq1.pop && rq2.pop;
  assign push2 = rq1.push && rq2.push;
  logic r_prior, w_prior;  //priority
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) w_prior <= 0;
    else if (push && !push2) w_prior <= ~w_prior;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) r_prior <= 0;
    else if (pop && !pop2) r_prior <= ~r_prior;
  end

  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) count <= 0;
    else if (pop && push) begin
      count <= ({rq2.pop, rq1.pop}=={rq2.push, rq1.push}) ? count : pop2 ? count - 1 : count + 1;
    end else if (pop) begin
      count <= pop2 ? count - 2 : count - 1;
    end else if (push) begin
      count <= push2 ? count + 2 : count + 1;
    end
  end

  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) w_ptr <= 0;
    else if (push) begin
      if (push2 || w_prior) w_ptr <= w_ptr + 1;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) r_ptr <= 0;
    else if (pop) begin
      if (pop2 || r_prior) r_ptr <= r_ptr + 1;
    end
  end
  assign empty = count == 0;
  assign almost_empty = count == 1;
  assign full = count == NUM;
  assign almost_full = count == NUM - 1;
 
  logic [INDEX-2:0] w_ptr_2, r_ptr_2;
  assign w_ptr_2 = w_ptr + 1;
  assign r_ptr_2 = r_ptr + 1;
  assign rq1.pop_data = r_prior ? fifo2[r_ptr] : fifo1[r_ptr];
  assign rq2.pop_data = r_prior ? fifo1[r_ptr_2] : fifo2[r_ptr];
  always_ff @(posedge i_clock) begin
    if (push && !i_reset && !i_flush) begin
      if (w_prior && push2) fifo1[w_ptr_2] <= rq2.push_data;
      else if (!w_prior) fifo1[w_ptr] <= rq1.push_data;
    end
  end
  always_ff @(posedge i_clock) begin
    if (push && !i_reset && !i_flush) begin
      if (w_prior) fifo2[w_ptr] <= rq1.push_data;
      else if (!w_prior && push2) fifo2[w_ptr] <= rq2.push_data;
    end
  end
endmodule
