module BTB #(
    NUM = 16
) (
    input i_clock,
    input i_reset,
    input bp::update_btb_t update,
    if_rq_btb.in i_rq
);
  localparam BTB_INDEX_WIDTH = $clog2(NUM);
  typedef struct packed {
    logic [31:BTB_INDEX_WIDTH+4] tag;
    logic [1:0] offset;
    logic [31:0] target;
  } btb_t;
  btb_t btbs[NUM];
  function logic [1:0] get_offset(input [31:0] pc);
    return pc[3:2];
  endfunction
  function logic [BTB_INDEX_WIDTH-1:0] get_index(input [31:0] pc);
    return pc[BTB_INDEX_WIDTH+3:4];
  endfunction
  function logic [31:BTB_INDEX_WIDTH+4] get_tag(input [31:0] pc);
    return pc[31:BTB_INDEX_WIDTH+4];
  endfunction
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM; i++) begin
      if (i_reset) btbs[i] <= 0;
      else if (update.valid && get_index(
              update.pc
          ) == i && get_offset(
              update.pc
          ) > btbs[i].offset) begin
        btbs[get_index(update.pc)].tag <= get_tag(update.pc);
        btbs[get_index(update.pc)].target <= update.upc;
        btbs[get_index(update.pc)].offset <= get_offset(update.pc);
      end
    end
  end
  function logic in_effect(logic [1:0] rq, offset);
    return rq == offset || rq==0 && offset==1 || rq==1&&offset==2 || rq==2&&offset==3;
  endfunction
  assign i_rq.hit = get_tag(
      i_rq.pc
  ) == btbs[get_index(
      i_rq.pc
  )].tag && in_effect(
      get_offset(i_rq.pc), btbs[get_index(i_rq.pc)].offset
  );
  assign i_rq.upc = btbs[get_index(i_rq.pc)].target;

endmodule
