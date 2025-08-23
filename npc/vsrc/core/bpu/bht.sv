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
    /* logic [29:0 ]_pc = {pc[31:4], 2'b0}; */
    /* return _pc[4:0] ^ _pc[9:5] ^ _pc[14:10] ^ _pc[19:15] ^ _pc[24:20] ^ _pc[29:25]; */
    return pc[INDEX+3:4];
  endfunction
  logic [NUM-1:0][WIDTH-1:0] bht;
  always @(posedge i_clock) begin
    for (int i = 0; i < NUM; i++) begin
      if (i_reset) bht[i] <= 0;
      else if (update.valid && hash(update.pc) == i) bht[i] <= {bht[i][WIDTH-2:0], update.taken};
    end
  end

  assign i_rq.index   = {bht[hash(i_rq.pc)], i_rq.pc[8:4]};
  assign update_index = {bht[hash(update.pc)], update.pc[8:4]};
endmodule
