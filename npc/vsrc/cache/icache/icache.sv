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
  cache_line_t cache[NUM_BLOCKS];
  logic [TAG_WIDTH-1:0] tag;
  logic [INDEX_WIDTH-1:0] index;
  logic [OFFSET_WIDTH-3:0] offset;
  assign tag = addr[31-:TAG_WIDTH];
  assign index = addr[OFFSET_WIDTH+:INDEX_WIDTH];
  assign offset = addr[OFFSET_WIDTH-1:2];
  logic [31:0] addr;
  always_ff @(posedge i_clock) begin
    if (i_rq.rq && i_rq.ready) begin
      addr <= i_rq.addr;
    end
  end
  assign i_rq.rdata = cache_line.data[offset*32+:32];
  logic hit;
  cache_line_t cache_line;
  assign cache_line = cache[index];
  assign hit = cache_line.valid && cache_line.tag == tag;

  logic flush;
  always_ff @(posedge i_clock) begin
    if (i_reset) flush <= 0;
    else if (i_rq.flush) flush <= 1;
    else if (flush && state == idle) flush <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) i_rq.flush_fin <= 0;
    else if (state == in_flush) i_rq.flush_fin <= 1;
    else if (i_rq.flush_fin) i_rq.flush_fin <= 0;
  end
  typedef enum logic [2:0] {
    idle,
    judge,
    in_flush,
    read_mem
  } state_t;
  state_t state;

  always_ff @(posedge i_clock) begin
    if (i_reset) state <= idle;
    else begin
      case (state)
        idle: begin
          if (flush) state <= in_flush;
          else if (i_rq.rq && !i_rq.flush) begin
            state <= judge;
          end
        end
        judge: begin
          if (hit) begin
            state <= idle;
          end else begin
            state <= read_mem;
          end
        end
        in_flush: begin
          state <= idle;
        end
        read_mem: begin
          if (o_rq.valid) state <= judge;
        end
        default: begin
          state <= idle;
        end
      endcase
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) o_rq.rq <= 0;
    else if (state == judge && !hit) o_rq.rq <= 1;
    else if (o_rq.rq && o_rq.ack) o_rq.rq <= 0;
  end
  assign o_rq.ready = 1;
  assign o_rq.addr  = addr;
  always_ff @(posedge i_clock) begin
    if (state == read_mem && o_rq.valid) cache[index].data <= o_rq.r_cache_line;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset || state == in_flush) begin
      for (int i = 0; i < NUM_BLOCKS; i++) begin
        cache[i].valid <= 0;
      end
    end else begin
      if (state == read_mem && o_rq.valid) cache[index].valid <= 1;
      else if (state == judge && !hit) cache[index].valid <= 0;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < NUM_BLOCKS; i++) begin
        cache[i].tag <= 0;
      end
    end else begin
      if (state == read_mem && o_rq.valid) cache[index].tag <= tag;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) i_rq.valid <= 0;
    else if (state == judge && hit && !i_rq.flush && !flush) i_rq.valid <= 1;
    else if (i_rq.valid && i_rq.ready) i_rq.valid <= 0;
  end
  /* always_ff @(posedge i_clock) begin */
  /*   if (i_reset && i_rq.flush && flush) i_rq.ack <= 0; */
  /*   else if (i_rq.rq && !i_rq.ack && state == idle) i_rq.ack <= 1; */
  /*   else if (i_rq.ack) i_rq.ack <= 0; */
  /* end */
  assign i_rq.cache_ready = state == idle;

endmodule
