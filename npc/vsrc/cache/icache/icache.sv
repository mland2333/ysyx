module ysyx_24110006_ICACHE #(
    parameter NUM_BLOCKS = 64,
    parameter NUM_WAYS = 1,
    parameter INSTS_PER_CACHELINE = 4,
    parameter BTB_SETS = 32
) (
    input i_clock,
    input i_reset,
    if_icache_rq.slave i_rq,
    if_mem_rq.master o_rq
);

  localparam BLOCK_SIZE = INSTS_PER_CACHELINE * 4;
  localparam NUM_SETS = NUM_BLOCKS / NUM_WAYS;
  localparam INDEX_WIDTH = $clog2(NUM_SETS);
  localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);
  localparam TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;
  localparam DATA_WIDTH = BLOCK_SIZE * 8;
  localparam DATA_OFFSET_WIDTH = $clog2(INSTS_PER_CACHELINE);
  localparam NUM_INDEX_WIDTH = $clog2(NUM_BLOCKS);
  typedef struct packed {
    logic [TAG_WIDTH-1:0] tag;
    logic [DATA_WIDTH-1:0] data;
    logic valid;
  } cache_line_t;
  typedef struct packed {
    logic [TAG_WIDTH-1:0] tag;
    logic [INDEX_WIDTH-1:0] index;
    logic [OFFSET_WIDTH-1:0] offset;
  } addr_info_t;
  cache_line_t cache[NUM_BLOCKS];
  addr_info_t addr_s1, addr_s2;
  logic hit_s1, hit_s2;
  logic [31:0] addr;

  logic valid_s1, valid_s2;
  logic ready_s1, ready_s2;
  cache_line_t cache_line_s1, cache_line_s2;
  logic rq_valid, ack_valid;
  logic mem_valid;
  bp::info_group_t bp_info_s1, bp_info_s2;
  logic in_tran, ready_s2_or, ready_s1_or;
  assign in_tran = !valid_s2 && !ready_s2;
  assign ready_s2_or = ready_s2 || (!in_tran && i_rq.ready);
  assign ready_s1_or = ready_s1 || ready_s2_or;
  always_ff @(posedge i_clock) begin
    if (i_reset) valid_s1 <= 0;
    else if (!valid_s1 && i_rq.rq && ready_s1) valid_s1 <= 1;
    else if (valid_s1 && !i_rq.rq && !ready_s1 && ready_s2_or) valid_s1 <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) ready_s1 <= 1;
    else if (!valid_s1 && i_rq.rq && ready_s1) ready_s1 <= 0;
    else if (valid_s1 && !i_rq.rq && !ready_s1 && ready_s2_or) ready_s1 <= 1;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) valid_s2 <= 0;
    else if (!valid_s2 && (!ready_s2 && mem_valid || valid_s1 && ready_s2 && hit_s1)) valid_s2 <= 1;
    else if (valid_s2 && (!valid_s1 || valid_s1 && !hit_s1) && i_rq.ready) valid_s2 <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) ready_s2 <= 1;
    else if (ready_s2 && valid_s1) ready_s2 <= 0;
    else if (!ready_s2 && !valid_s1 && valid_s2 && i_rq.ready) ready_s2 <= 1;
  end

  always_ff @(posedge i_clock) begin
    if (i_rq.rq && ready_s1_or) addr_s1 <= i_rq.addr;
  end
  always_ff @(posedge i_clock) begin
    if (i_rq.rq && ready_s1_or) bp_info_s1 <= i_rq.bp_info_in;
  end
  assign cache_line_s1 = cache[addr_s1.index];
  assign hit_s1 = cache_line_s1.valid && cache_line_s1.tag == addr_s1.tag;

  always_ff @(posedge i_clock) begin
    if (valid_s1 && ready_s2_or) addr_s2 <= addr_s1;
  end
  always_ff @(posedge i_clock) begin
    if (valid_s1 && ready_s2_or) bp_info_s2 <= bp_info_s1;
  end
  assign cache_line_s2 = cache[addr_s2.index];
  assign hit_s2 = cache_line_s2.valid && cache_line_s2.tag == addr_s2.tag;

  always_ff @(posedge i_clock) begin
    if (i_reset) rq_valid <= 0;
    else if (valid_s1 && !hit_s1 && ready_s2_or) rq_valid <= 1;
    else if (rq_valid && ack_valid) rq_valid <= 0;
  end
  assign o_rq.rq = rq_valid;
  assign ack_valid = o_rq.ack;
  assign o_rq.addr = addr_s2;
  assign o_rq.ready = 1;
  assign mem_valid = o_rq.valid;

  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM_BLOCKS; i++) begin
      if (i_reset || i_rq.flush) cache[i].valid <= 0;
      else if (valid_s1 && !hit_s1 && cache[i].valid && addr_s1.index == i) cache[i].valid <= 0;
      else if (mem_valid && addr_s2.index == i) cache[i].valid <= 1;
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM_BLOCKS; i++) begin
      if (mem_valid && addr_s2.index == i) cache[i].tag <= addr_s2.tag;
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM_BLOCKS; i++) begin
      if (mem_valid && addr_s2.index == i) cache[i].data <= o_rq.r_cache_line;
    end
  end

  assign i_rq.cache_ready = ready_s1_or;
  assign i_rq.valid = valid_s2;
  assign i_rq.rdata1 = cache_line_s2.data[{addr_s2.offset, 3'b000}+:32];
  addr_info_t addr_s2_2;
  assign addr_s2_2.offset = addr_s2.offset + 4;
  assign i_rq.rdata2 = addr_s2.offset[OFFSET_WIDTH-1:OFFSET_WIDTH-3] == 2'b11 ? 0 : cache_line_s2.data[{addr_s2_2.offset, 3'b000}+:32];
  assign i_rq.pc = addr_s2;
  assign i_rq.bp_info_out = bp_info_s2;

endmodule
