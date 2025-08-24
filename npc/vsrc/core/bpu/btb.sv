module BTB #(
    NUM = 16
) (
    input i_clock,
    input i_reset,
    input bp::update_btb_t update,
    if_rq_btb.in i_rq
);
  localparam INDEX = $clog2(NUM);
  typedef struct packed {
    logic [31:INDEX+4] tag;
    logic [1:0] offset;
    logic [31:0] target;
  } btb_t;
  btb_t btbs[NUM];
  logic [NUM-1:0] valid;
  function logic [1:0] get_offset(input [31:0] pc);
    return pc[3:2];
  endfunction
  function logic [INDEX-1:0] get_index(input [31:0] pc);
    return pc[INDEX+3:4];
  endfunction
  function logic [31:INDEX+4] get_tag(input [31:0] pc);
    return pc[31:INDEX+4];
  endfunction
  logic [INDEX-1:0] update_index, rq_index;
  logic [1:0] update_offset, rq_offset;
  logic [31:INDEX+4] update_tag, rq_tag;
  assign update_index = get_index(update.pc);
  assign rq_index = get_index(i_rq.pc);
  assign update_offset = get_offset(update.pc);
  assign rq_offset = get_offset(i_rq.pc);
  assign update_tag = get_tag(update.pc);
  assign rq_tag = get_tag(i_rq.pc);
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM; i++) begin
      if (i_reset) begin
        valid[i] <= 0;
      end else if (update.valid && update_index == i && (!valid[i] || update_offset <= btbs[i].offset)) begin
        btbs[i].tag <= update_tag;
        btbs[i].target <= update.upc;
        btbs[i].offset <= update_offset;
        valid[i] <= 1;
      end
    end
  end
  function logic in_effect(logic [1:0] rq, offset);
    return rq == offset || rq==0 && offset==1 || rq==1&&offset==2 || rq==2&&offset==3;
  endfunction
  assign i_rq.hit = rq_tag == btbs[rq_index].tag && in_effect(rq_offset, btbs[rq_index].offset);
  assign i_rq.upc = btbs[rq_index].target;
  assign i_rq.inst_valid = i_rq.hit && i_rq.pht_hit && rq_offset == btbs[rq_index].offset || rq_offset == 2'b11 ? 2'b01 : 2'b11;
endmodule
