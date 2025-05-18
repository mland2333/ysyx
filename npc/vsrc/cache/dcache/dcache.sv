//状态机
`include "common_config.sv"
module ysyx_24110006_DCACHE #(
    parameter NUM_BLOCKS = 64,
    parameter NUM_WAYS = 1,
    parameter DATA_PER_CACHELINE = 8
) (
    input i_clock,
    input i_reset,
    input i_flush,
    output logic o_fin,
    //lsu <--> cache
    if_lsu_dcache.slave i_lsu_rq,
    //cache <--> axi
    if_dcache_axi.master o_axi_rq
);
  localparam BLOCK_SIZE = DATA_PER_CACHELINE * 4;
  localparam NUM_SETS = NUM_BLOCKS / NUM_WAYS;
  localparam INDEX_WIDTH = $clog2(NUM_SETS);
  localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);
  localparam TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;
  localparam DATA_WIDTH = BLOCK_SIZE * 8;
  localparam DATA_OFFSET_WIDTH = $clog2(DATA_PER_CACHELINE);
  localparam NUM_INDEX_WIDTH = $clog2(NUM_BLOCKS);
  typedef struct packed {
    logic [TAG_WIDTH-1:0] tag;
    logic [DATA_WIDTH-1:0] data;
    logic valid;
    logic dirty;
  } cache_line_t;
  cache_line_t cache[NUM_BLOCKS];
  logic [TAG_WIDTH-1:0] tag;
  logic [INDEX_WIDTH-1:0] index;
  logic [OFFSET_WIDTH-3:0] offset;
  logic in_flush;
  assign in_flush = state == flush || state == flush_write;
  assign tag = addr[31-:TAG_WIDTH];
  assign index = in_flush ? flush_index : addr[OFFSET_WIDTH+:INDEX_WIDTH];
  assign offset = addr[OFFSET_WIDTH-1:2];
  logic wen, ren;
  logic [31:0] addr, wdata;
  logic [3:0] wmask;
  always_ff @(posedge i_clock) begin
    if (i_lsu_rq.rq && i_lsu_rq.ready) begin
      wen   <= i_lsu_rq.wen;
      ren   <= i_lsu_rq.ren;
      addr  <= i_lsu_rq.addr;
      wdata <= i_lsu_rq.wdata;
      wmask <= i_lsu_rq.wmask;
    end
  end
  assign i_lsu_rq.rdata = cache_line.data[offset*32+:32];
  logic hit, dirty;
  cache_line_t cache_line;
  assign cache_line = cache[index];
  assign hit = cache_line.valid && cache_line.tag == tag;
  assign dirty = cache_line.dirty;
  typedef enum logic [2:0] {
    idle,
    judge,
    flush,
    flush_write,
    read_mem,
    write_mem
  } state_t;
  state_t state;

  always_ff @(posedge i_clock) begin
    if (i_reset) state <= idle;
    else begin
      case (state)
        idle: begin
          if (i_flush) state <= flush;
          else if (i_lsu_rq.rq) begin
            state <= judge;
          end
        end
        judge: begin
          if (hit) begin
            state <= idle;
          end else begin
            if (dirty) state <= write_mem;
            else state <= read_mem;
          end
        end
        write_mem: begin
          if (o_axi_rq.valid) state <= judge;
        end
        read_mem: begin
          if (o_axi_rq.valid) state <= judge;
        end
        flush: begin
          if (cache_line.valid && cache_line.dirty) state <= flush_write;
          else if (flush_index == NUM_BLOCKS-1) state <= idle;
        end
        flush_write: begin
          if (o_axi_rq.valid) begin
            if(flush_index == NUM_BLOCKS-1) state <= idle;
            else state <= flush;
          end
        end
        default: begin
          state <= idle;
        end
      endcase
    end
  end
  always_ff@(posedge i_clock)begin
    if(i_reset) o_fin <= 0;
    else if(in_flush && !(cache_line.valid && cache_line.dirty) && flush_index == NUM_BLOCKS-1) o_fin <= 1;
    else if(o_fin) o_fin <= 0;
  end
  logic need_flush;
  assign need_flush = (state == flush) && cache_line.valid && cache_line.dirty;
  always_ff @(posedge i_clock) begin
    if (i_reset) o_axi_rq.rq <= 0;
    else if (state == judge && !hit || need_flush) o_axi_rq.rq <= 1;
    else if (o_axi_rq.rq && o_axi_rq.ack) o_axi_rq.rq <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) o_axi_rq.wen <= 0;
    else if (state == judge && !hit && dirty || need_flush) o_axi_rq.wen <= 1;
    else if (o_axi_rq.rq && o_axi_rq.ack) o_axi_rq.wen <= 0;
  end
  assign o_axi_rq.ready = 1;
  assign o_axi_rq.addr = in_flush ? {cache[index].tag, index, (32 - TAG_WIDTH - INDEX_WIDTH)'(0)} : addr;
  assign o_axi_rq.w_cache_line = cache_line.data;
  always_ff @(posedge i_clock) begin
    if (state == read_mem && o_axi_rq.valid) cache[index].data <= o_axi_rq.r_cache_line;
    else if (state == judge && hit) begin
      for (int i = 0; i < 4; i++) begin
        if (wmask[i]) cache[index].data[offset*32+i*8+:8] <= wdata[i*8+:8];
      end
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < NUM_BLOCKS; i++) begin
        cache[i].valid <= 0;
      end
    end else begin
      if (state == read_mem && o_axi_rq.valid) cache[index].valid <= 1;
      else if (state == judge && !hit) cache[index].valid <= 0;
      else if (state == flush) cache[flush_index].valid <= 0;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < NUM_BLOCKS; i++) begin
        cache[i].dirty <= 0;
      end
    end else begin
      if (state == read_mem && o_axi_rq.valid) cache[index].dirty <= 0;
      else if (state == judge && hit && wen) cache[index].dirty <= 1;
      else if (state == flush) cache[flush_index].dirty <= 0;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < NUM_BLOCKS; i++) begin
        cache[i].tag <= 0;
      end
    end else begin
      if (state == read_mem && o_axi_rq.valid) cache[index].tag <= tag;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) i_lsu_rq.valid <= 0;
    else if (state == judge && hit) i_lsu_rq.valid <= 1;
    else if (i_lsu_rq.valid && i_lsu_rq.ready) i_lsu_rq.valid <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) i_lsu_rq.ack <= 0;
    else if (i_lsu_rq.rq && !i_lsu_rq.ack) i_lsu_rq.ack <= 1;
    else if (i_lsu_rq.ack) i_lsu_rq.ack <= 0;
  end

  logic [NUM_INDEX_WIDTH-1:0] flush_index;
  always_ff @(posedge i_clock) begin
    if (i_reset) flush_index <= 0;
    else if (state == flush && !(cache_line.valid && cache_line.dirty))
      flush_index <= flush_index + 1;
  end

endmodule
