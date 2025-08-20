module ysyx_24110006_BTB #(
    BTB_NUMS = 16
) (
    input i_clock,
    input i_reset,
    input bp::btb_update_t update,
    if_rq_btb.in i_rq[2]
);
  localparam BTB_INDEX_WIDTH = $clog2(BTB_NUMS);
  typedef struct packed {
    logic ret, call;
    logic [31:BTB_INDEX_WIDTH+2] tag;
    logic [31:0] target;
  } btb_t;
  btb_t btbs[BTB_NUMS];
  function logic [BTB_INDEX_WIDTH-1:0] get_index(input [31:0] pc);
    return pc[BTB_INDEX_WIDTH+1:2];
  endfunction
  function logic [31:BTB_INDEX_WIDTH+2] get_tag(input [31:0] pc);
    return pc[31:BTB_INDEX_WIDTH+2];
  endfunction
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < BTB_NUMS; i++) begin
      if (i_reset) btbs[i] <= 0;
      else if (update.valid && get_index(update.pc) == i) begin
        btbs[get_index(update.pc)].tag <= get_tag(update.pc);
        btbs[get_index(update.pc)].target <= update.upc;
        btbs[get_index(update.pc)].ret <= update.ret;
        btbs[get_index(update.pc)].call <= update.call;
      end
    end
  end
  generate
    for (genvar i = 0; i < 2; i++) begin
      assign i_rq[i].hit  = get_tag(i_rq[i].pc) == btbs[get_index(i_rq[i].pc)].tag;
      assign i_rq[i].upc  = btbs[get_index(i_rq[i].pc)].target;
      assign i_rq[i].ret  = btbs[get_index(i_rq[i].pc)].ret;
      assign i_rq[i].call = btbs[get_index(i_rq[i].pc)].call;
    end
  endgenerate

endmodule
