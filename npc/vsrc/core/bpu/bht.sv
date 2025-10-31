module BHT #(
    NUM   = 32,
    WIDTH = 5
) (
    input i_clock,
    input i_reset,
    input bp::update_bht_t update,
    output [9:0] update_index,
    if_rq_bht.in i_rq
);
  localparam INDEX = $clog2(NUM);
  function automatic logic [INDEX-1:0] hash(logic [31:0] pc);
    return pc[31:25] ^ pc[24:18] ^ pc[17:11] ^ pc[10:4] ;
    /* return pc[INDEX+3:4]; */
  endfunction
  logic [NUM-1:0][WIDTH-1:0] bht;
  always @(posedge i_clock) begin
    for (int i = 0; i < NUM; i++) begin
      if (i_reset) bht[i] <= 0;
      else if (update.valid && hash(update.pc) == i) bht[i] <= {bht[i][WIDTH-2:0], update.taken};
    end
  end

  assign i_rq.index   = {bht[hash(i_rq.pc)], i_rq.pc[6:4]};
  assign update_index = {bht[hash(update.pc)], update.pc[6:4]};
endmodule
