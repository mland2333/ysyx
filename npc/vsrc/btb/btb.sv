module ysyx_241106_BTB #(
    parameter BTB_SETS = 32
) (
    input i_clock,
    input i_reset,
    if_btb_rq.slave i_rq
);


  localparam BTB_TAG_BEGIN = $clog2(BTB_SETS) + 2;
  localparam BTB_INDEX_WIDTH = $clog2(BTB_SETS);

  typedef struct packed {
    logic valid;
    logic [31:BTB_TAG_BEGIN] tag;
    logic [31:2] target;
  } btb_t;
  btb_t btb;
  logic [BTB_INDEX_WIDTH+2-1:2] index;
  assign index = i_rq.pc[BTB_INDEX_WIDTH+2-1:2];
  always @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < BTB_SETS; i++) btb[i].valid <= 0;
    end else if (i_rq.update) begin
      btb[index] <= {1, i_rq.pc[31:BTB_TAG_BEGIN], i_rq.upc[31:2]};
    end
  end

  assign i_rq.hit = i_rq.pc[31:BTB_TAG_BEGIN] == btb[index].tag;
  assign i_rq.btb_pc = {btb[index].target, 2'b0};

endmodule
