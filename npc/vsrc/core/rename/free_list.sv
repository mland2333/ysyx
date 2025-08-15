module DOUBLE_PROT_FREE_LIST #(
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
    almost_full,
    input rename::free_list_backup_t backup
);
  localparam INDEX = $clog2(NUM);
  logic [NUM/2-1:0][INDEX-1:0] fifo1;
  logic [NUM/2-1:0][INDEX-1:0] fifo2;

  logic [INDEX-2:0] w_ptr, r_ptr;
  logic [INDEX:0] count;
  logic pop, push, pop2, push2;
  assign pop   = rq1.pop || rq2.pop;
  assign push  = rq1.push || rq2.push;
  assign pop2  = rq1.pop && rq2.pop;
  assign push2 = rq1.push && rq2.push;
  logic r_prior, w_prior;  //priority
  always_ff @(posedge i_clock) begin
    if (i_reset) w_prior <= 0;
    else if(i_flush) w_prior <= backup.w_prior;
    else if (push && !push2) w_prior <= ~w_prior;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) r_prior <= 0;
    else if (i_flush) r_prior <= backup.r_prior;
    else if (pop && !pop2) r_prior <= ~r_prior;
  end

  always_ff @(posedge i_clock) begin
    if (i_reset) count <= NUM;
    else if (i_flush) count <= backup.count;
    else if (pop && push) begin
      count <= ({rq2.pop, rq1.pop}=={rq2.push, rq1.push}) ? count : pop2 ? count - 1 : count + 1;
    end else if (pop) begin
      count <= pop2 ? count - 2 : count - 1;
    end else if (push) begin
      count <= push2 ? count + 2 : count + 1;
    end
  end

  always_ff @(posedge i_clock) begin
    if (i_reset) w_ptr <= 0;
    else if (i_flush) w_ptr <= backup.w_ptr;
    else if (push) begin
      if (push2 || w_prior) w_ptr <= w_ptr + 1;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) r_ptr <= 0;
    else if (i_flush) r_ptr <= backup.r_ptr;
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
    for (int i = 0; i < NUM/2; i++) begin
      if (i_reset) fifo1[i] <= {(INDEX-1)'(i), 1'b0};
      else if (i_flush) fifo1[i] <= backup.fifo1[i];
      else if (push) begin
        if (w_prior && push2 && w_ptr_2 == i) fifo1[i] <= rq2.push_data;
        else if (!w_prior && w_ptr == i) fifo1[i] <= rq1.push_data;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM/2; i++) begin
      if (i_reset) fifo2[i] <= {(INDEX-1)'(i), 1'b1};
      else if (i_flush) fifo2[i] <= backup.fifo2[i];
      else if (push) begin
        if (w_prior && w_ptr == i) fifo2[i] <= rq1.push_data;
        else if (!w_prior && push2 && w_ptr == i) fifo2[i] <= rq2.push_data;
      end
    end
  end

endmodule








