module ysyx_24110006_BTB #(
    BTB_NUMS = 16
) (
    input i_clock,
    input i_reset,
    input bp::btb_update_t update,
    if_rq_btb.in i_rq
);
localparam BTB_INDEX_WIDTH = $clog2(BTB_NUMS);
  typedef struct packed{
    logic [31:BTB_INDEX_WIDTH+2] tag;
    logic [31:0] target;
  }btb_t;
  btb_t btbs[BTB_NUMS];
  function logic [BTB_INDEX_WIDTH-1:0] get_index(input [31:0] pc);
    return pc[BTB_INDEX_WIDTH+1:2];
  endfunction
  function logic [31:BTB_INDEX_WIDTH+2] get_tag(input [31:0] pc);
    return pc[31:BTB_INDEX_WIDTH+2];
  endfunction
  always_ff @(posedge i_clock) begin
    for(int i = 0; i<BTB_NUMS; i++)begin
      if(i_reset) btbs[i] <= 0;
      else if(update.valid && get_index(update.pc) == i) begin
        btbs[get_index(update.pc)].tag <= get_tag(update.pc);
        btbs[get_index(update.pc)].target <= update.upc;
      end
    end
  end
  assign i_rq.hit = get_tag(i_rq.pc) == btbs[get_index(i_rq.pc)].tag;
  assign i_rq.upc = btbs[get_index(i_rq.pc)].target;

endmodule
