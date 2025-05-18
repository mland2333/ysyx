//与访存接口分离
module ysyx_24110006_DCACHE_OLD #(
    parameter NUM_BLOCKS = 64,
    parameter NUM_WAYS = 1,
    parameter DATA_PER_CACHELINE = 8
) (
    input i_clock,
    input i_reset,
    //lsu <--> cache
    if_lsu_dcache.slave i_lsu,
    //cache <--> axi
    if_dcache_axi.master o_axi
);
  localparam BLOCK_SIZE = DATA_PER_CACHELINE * 4;
  localparam NUM_SETS = NUM_BLOCKS / NUM_WAYS;
  localparam INDEX_WIDTH = $clog2(NUM_SETS);
  localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);
  localparam TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;
  localparam DATA_WIDTH = BLOCK_SIZE * 8;
  localparam DATA_OFFSET_WIDTH = $clog2(DATA_PER_CACHELINE);

  typedef struct packed {
    logic [TAG_WIDTH-1:0] tag;
    logic [DATA_WIDTH-1:0] data;
    logic [DATA_PER_CACHELINE-1:0] valid;
    logic dirty;
  } cache_line_t;
  cache_line_t cache[NUM_BLOCKS];
  logic [TAG_WIDTH-1:0] cache_tag;
  logic [INDEX_WIDTH-1:0] cache_index;
  logic [OFFSET_WIDTH-3:0] cache_offset;
  logic [31:0] cache_wdata;
  logic [3:0] cache_wmask;
  assign cache_tag = stall ? s1_tag : s0_tag;
  assign cache_index = stall ? s1_index : s0_index;
  assign cache_offset = stall ? (state == write_mem ? write_offset : s1_offset) : s0_offset;
  assign cache_wdata = stall ? s1_wdata : s0_wdata;
  assign cache_line = cache[cache_index];

  logic [31:0] rdata;
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM_BLOCKS; i++) begin
      for (int j = 0; j < DATA_PER_CACHELINE; j++) begin
        if (i == cache_index) begin
          if (j == cache_offset) begin
            if (s0_valid && s1_ready && hit && s0_wen || stall && hit && s1_wen) begin
              for (int k = 0; k < 4; k++) begin
                if (cache_wmask[k]) cache[i].data[j*32+k*8] <= cache_wdata[k*8+:8];
              end
            end else if (o_axi.rdata_valid) begin
              cache[i].data[j*32+:32] <= o_axi.rdata_mem;
            end
          end
        end
      end
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < NUM_BLOCKS; i++) begin
        cache[i].valid <= 0;
      end
    end else begin
      if (o_axi.rdata_valid) cache[cache_index].valid[cache_offset] <= 1;
      else if (s0_valid && s1_ready && !hit) cache[cache_index].valid <= 0;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < NUM_BLOCKS; i++) begin
        cache[i].dirty <= 0;
      end
    end else begin
      if (o_axi.rdata_valid) cache[cache_index].dirty <= 1;
      else if (state == mem) cache[cache_index].dirty <= 0;
    end
  end
  always_ff @(posedge i_clock) begin
    if ((s0_valid && s0_hit || state == ready) && !s0_wen)
      rdata <= cache[cache_index].data[cache_offset*32+:32];
  end

  logic stall;
  always_ff @(posedge i_clock) begin
    if (i_reset) stall <= 0;
    else if (s0_valid && s1_ready && !hit) stall <= 1;
    else if (stall && s1_valid && s1_hit) stall <= 0;
  end
  assign i_lsu.ready = s0_ready || s1_ready;
  
  //stage0
  logic s0_wen, s0_ren;
  logic [31:0] s0_addr, s0_wdata;
  logic [3:0] s0_wmask;
  logic [TAG_WIDTH-1:0] s0_tag;
  logic [INDEX_WIDTH-1:0] s0_index;
  logic [OFFSET_WIDTH-3:0] s0_offset;
  cache_line_t cache_line;
  assign s0_tag = s0_addr[31-:TAG_WIDTH];
  assign s0_index = s0_addr[OFFSET_WIDTH+:INDEX_WIDTH];
  assign s0_offset = s0_addr[OFFSET_WIDTH-1:2];
  logic hit;
  logic stall;
  assign hit = cache_line.valid && cache_tag == cache_line.tag;
  always_ff @(posedge i_clock) begin
    if (i_reset) stall <= 0;
    else if (s0_valid && !hit) stall <= 0;
    else if (stall && hit) stall <= 1;
  end
  always_ff @(posedge i_clock) begin
    if (i_lsu.rq && i_lsu.ready) begin
      s0_wen   <= i_lsu.wen;
      s0_ren   <= i_lsu.ren;
      s0_addr  <= i_lsu.addr;
      s0_wdata <= i_lsu.wdata;
      s0_wmask <= i_lsu.wmask;
    end
  end
  logic s0_valid, s0_ready;
  always_ff @(posedge i_clock) begin
    if (i_reset) s0_valid <= 0;
    else if (i_lsu.rq) s0_valid <= 1;
    else if (s0_valid && s1_ready) s0_valid <= 0;
  end

  always_ff @(posedge i_clock) begin
    if (i_reset) s0_ready <= 1;
    else if (i_lsu.rq && !s1_ready) s0_ready <= 0;
    else if (!s0_ready && s1_ready && !i_lsu.rq) s0_ready <= 1;
  end

  //stage1
  logic s1_valid, s1_ready;
  always_ff @(posedge i_clock) begin
    if (i_reset) s1_valid <= 0;
    else if (s0_valid && !s0_hit) s1_valid <= 1;
    else if (s1_valid && s2_ready) s1_valid <= 0;
  end

  always_ff @(posedge i_clock) begin
    if (i_reset) s1_ready <= 1;
    else if (s0_valid && !hit && s1_ready) s1_ready <= 0;
    else if (!s1_ready && hit) s1_ready <= 1;
  end
  logic s1_wen, s1_ren;
  logic [31:0] s1_addr, s1_wdata;
  logic [3:0] s1_wmask;
  logic [TAG_WIDTH-1:0] s1_tag;
  logic [INDEX_WIDTH-1:0] s1_index;
  logic [OFFSET_WIDTH-3:0] s1_offset;
  assign s1_tag = s1_addr[31-:TAG_WIDTH];
  assign s1_index = s1_addr[OFFSET_WIDTH+:INDEX_WIDTH];
  assign s1_offset = s1_addr[OFFSET_WIDTH-1:2];
  always_ff @(posedge i_clock) begin
    if (s0_valid && s1_ready) begin
      s1_wen   <= s0_wen;
      s1_ren   <= s0_ren;
      s1_addr  <= s0_addr;
      s1_wdata <= s0_wdata;
      s1_wmask <= s0_wmask;
    end
  end

  //stage2
  logic s2_valid, s2_ready;
  always_ff @(posedge i_clock) begin
    if (i_reset) s2_valid <= 0;
  end

  always_ff @(posedge i_clock) begin
    if (i_reset) s2_ready <= 1;
    else if (s2_ready && s1_miss) s2_ready <= 0;
  end

  logic s2_wen, s2_ren;
  logic [31:0] s2_addr, s1_wdata;
  logic [3:0] s2_wmask;
  always_ff @(posedge i_clock) begin
    if (s1_valid && s2_ready) begin
      s2_wen   <= s1_wen;
      s2_ren   <= s1_ren;
      s2_addr  <= s1_addr;
      s2_wdata <= s1_wdata;
      s2_wmask <= s1_wmask;
    end
  end
  
  //miss state
  typedef enum logic [2:0] {
    idle,
    mem,
    read_mem,
    write_mem,
    ready,
    fencei
  } state_t;
  state_t state;
  always_ff @(posedge i_clock) begin
    if (i_reset) state <= idle;
    else begin
      case (state)
        idle: begin
          if (s0_valid && !hit) begin
            state <= mem;
          end
        end
        mem: begin
          if (cache[s1_index].dirty) state <= write_mem;
          else state <= read_mem;
        end
        write_mem: begin
          if (o_axi.fin_w) begin
            if (fencei_fin) state <= ready;
            else if (!fencei) state <= read_mem;
          end
        end
        read_mem: begin
          if (o_axi.fin_r) state <= ready;
        end
        ready: begin
          state <= idle;
        end
        default: begin
          state <= idle;
        end
      endcase
    end
  end
  
  // Map interface signals for AXI
  logic o_rq_mem, o_wen_mem;
  logic o_rdata_ready, o_wdata_valid, o_wlast;
  logic [31:0] o_wdata_mem;
  
  always_ff @(posedge i_clock) begin
    if (i_reset) o_rq_mem <= 0;
    else begin
      if (state == mem) o_rq_mem <= 1;
      else if (o_rq_mem && o_axi.rq_ack) o_rq_mem <= 0;
    end
  end
  
  always_ff @(posedge i_clock) begin
    if (i_reset) o_wen_mem <= 0;
    else begin
      if (state == mem && s1_wen) o_wen_mem <= 1;
      else if (o_wen_mem && o_rq_mem && o_axi.rq_ack) o_wen_mem <= 0;
    end
  end
  
  assign o_rdata_ready = 1;
  assign o_wdata_valid = 1;
  assign o_wdata_mem = cache_line.data[write_index*32+:32];
  assign o_wlast = write_num == DATA_PER_CACHELINE;
  
  logic [DATA_OFFSET_WIDTH-1:0] read_index, write_index, write_num;
  always_ff @(posedge i_clock) begin
    if (i_reset || o_axi.fin_r) read_index <= 0;
    else if (state == mem && !s1_wen) read_index <= s1_offset;
    else if (o_axi.rdata_valid) read_index <= read_index + 1;
  end
  
  always_ff @(posedge i_clock) begin
    if (i_reset || o_axi.fin_w) write_index <= 0;
    else if (state == mem && s1_wen) write_index <= s1_offset;
    else if (o_axi.wdata_ready && o_wdata_valid) write_index <= write_index + 1;
  end
  
  always_ff @(posedge i_clock) begin
    if (i_reset || state == mem && s1_wen) write_num <= 0;
    else if (o_axi.wdata_ready && o_wdata_valid) write_num <= write_num + 1;
  end
  
  // Connect interface signals
  assign i_lsu.rdata = rdata;
  assign i_lsu.ack = s1_valid && hit;
  
  assign o_axi.rq_mem = o_rq_mem;
  assign o_axi.wen_mem = o_wen_mem;
  assign o_axi.addr = s1_addr;
  assign o_axi.wdata_mem = o_wdata_mem;
  assign o_axi.wdata_valid = o_wdata_valid;
  assign o_axi.wlast = o_wlast;
  assign o_axi.rdata_ready = o_rdata_ready;
endmodule
