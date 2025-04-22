`include "common_config.sv"
module ysyx_24110006_DCACHE#(
    parameter NUM_BLOCKS = 64,
    parameter NUM_WAYS = 1,
    parameter DATA_PER_CACHELINE = 8
  )(
  input i_clock,
  input i_reset,
  input [31:0] i_addr,
  input [31:0] i_wdata,
  output logic [31:0] o_rdata,
  input [3:0] i_wmask,
  input i_fencei,
  input logic i_valid,
  output logic o_ready,
  output logic o_valid,
  input i_wen,
  if_axi.master o_axi
);

logic wen;
always_ff@(posedge i_clock)begin
  if(i_valid && o_ready) wen <= i_wen;
end
logic [31:0] addr;
always_ff@(posedge i_clock)begin
  if(i_valid && o_ready) addr <= i_addr;
end
logic [3:0] wmask;
always_ff@(posedge i_clock)begin
  if(i_valid && o_ready) wmask <= i_wmask;
end
logic [31:0] wdata;
always_ff@(posedge i_clock)begin
  if(i_valid && o_ready) wdata <= i_wdata;
end

logic [31:0] tran_addr;
always_ff@(posedge i_clock)begin
  if(i_valid && state == idle) tran_addr <= i_addr;
end
logic tran_wen;
always_ff@(posedge i_clock)begin
  if(i_valid && state == idle) tran_wen <= i_wen;
end
/* always_ff@(posedge i_clock)begin */
/*   if(i_reset)begin */
/*     o_valid <= 0; */
/*   end */
/*   else begin */
/*     if(i_valid && state == idle && hit) */
/*       o_valid <= 1; */
/*     else if(o_valid) */
/*       o_valid <= 0; */
/*   end */
/* end */
assign o_valid = state == idle && hit;
assign o_ready = state == idle;
/* always_ff@(posedge i_clock)begin */
/*   if(i_reset)begin */
/*     o_ready <= 1; */
/*   end */
/*   else begin */
/*     if(state == idle && i_valid && !hit && o_ready) */
/*       o_ready <= 0; */
/*     else if(!o_ready && state == idle) */
/*       o_ready <= 1; */
/*   end */
/* end */


localparam BLOCK_SIZE = DATA_PER_CACHELINE * 4;
localparam NUM_SETS = NUM_BLOCKS / NUM_WAYS;
localparam INDEX_WIDTH = $clog2(NUM_SETS);
localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);
localparam TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;
localparam DATA_WIDTH = BLOCK_SIZE*8;
localparam DATA_OFFSET_WIDTH = $clog2(DATA_PER_CACHELINE);

wire [TAG_WIDTH-1:0] tag = i_addr[31 -: TAG_WIDTH];
wire [INDEX_WIDTH-1:0] index = i_addr[OFFSET_WIDTH +: INDEX_WIDTH];
wire [OFFSET_WIDTH-3:0] offset = i_addr[OFFSET_WIDTH-1:2];


wire [TAG_WIDTH-1:0] tran_tag = tran_addr[31 -: TAG_WIDTH];
wire [INDEX_WIDTH-1:0] tran_index = tran_addr[OFFSET_WIDTH +: INDEX_WIDTH];
wire [OFFSET_WIDTH-3:0] tran_offset = tran_addr[OFFSET_WIDTH-1:2];
/* wire [TAG_WIDTH-1:0] read_tag = addr[31 -: TAG_WIDTH]; */
/* wire [INDEX_WIDTH-1:0] read_index = addr[OFFSET_WIDTH +: INDEX_WIDTH]; */
/* wire [OFFSET_WIDTH-3:0] read_offset = addr[OFFSET_WIDTH-1:2]; */

typedef struct packed {
  logic [TAG_WIDTH-1:0] tag;
  logic [DATA_WIDTH-1:0] data;
  logic [DATA_PER_CACHELINE-1:0] valid;
  logic dirty;
}cacheline_t;
typedef enum logic [2:0] {
  idle, read_mem, write_mem, ready, fencei
} state_t;
typedef enum logic [1:0] {
  idle, trans_begin, trans, trans_end
} fencei_state_t;

cacheline_t cache [NUM_SETS];

always_comb begin
  integer i;
  o_rdata = 0;
  for(i=0; i<NUM_SETS;i=i+1)begin
    integer j;
    for(j=0; j<DATA_PER_CACHELINE; j=j+1)begin
      o_rdata = o_rdata | ({32{(index==i) & (offset==j)}} & cache[i].data[32*j +:32]);
    end
  end
end

state_t state;
logic hit;
logic valid_ok;
logic tag_ok;
logic [NUM_SETS-1:0] indexs;
fencei_state_t fencei_state;
always_comb begin
  integer i;
  for(i=0; i<NUM_SETS; i=i+1)
    indexs[i] = index == i;
end
always_comb begin
  integer i;
  valid_ok = 0;
  for(i=0; i<NUM_SETS; i=i+1)begin
    integer j;
    for(j=0; j<DATA_PER_CACHELINE; j=j+1)begin
      valid_ok = valid_ok | indexs[i] & (offset == j) & cache[i].valid[j];
    end
  end
end

always_comb begin
  integer i;
  tag_ok = 0;
  for(i=0; i<NUM_SETS; i=i+1)begin
    tag_ok = tag_ok | indexs[i] & (cache[i].tag == tag);
  end
end

assign hit = valid_ok & tag_ok;
logic axi_busy;
assign axi_busy = state != idle;
always_ff @(posedge i_clock)begin
  if(i_reset)begin
    state <= idle;
  end
  else begin
    case(state)
      idle:begin
        if(i_valid && i_fencei)begin
          state <= fencei;
        end
        else if(i_valid && !hit)begin
          if(cache[index].dirty && i_wen) state <= write_mem;
          else state <= read_mem;
        end
      end
      write_mem:begin
        if(o_axi.bvalid)
          state <= read_mem;
      end
      read_mem:begin
        if(o_axi.rlast && o_axi.rvalid)
          state <= ready;
      end
      ready:begin
        state <= idle;
      end
      fencei:begin
        if(fencei_wb_finish)
          state <= idle;
      end
      default:begin
        state <= idle;
      end
    endcase
  end
end

reg [$clog2(NUM_BLOCKS)-1:0] fencei_nums;
always_ff@(posedge i_clock)begin
  if(i_reset) fencei_nums <= 0;
  else if(fencei_state == trans_begin && !cacheline_dirty || fencei_state == trans && bvalid && bready) fencei_nums <= fencei_nums + 1;
end
logic cacheline_dirty;
assign cacheline_dirty = cache[fencei_nums].dirty;
always_ff@(posedge i_clock)begin
  if(i_reset) fencei_state <= idle;
  else begin
    case(fencei_state)
      idle:begin
        if(state <= fencei) state <= trans_begin;
      end
      trans_begin:begin
        if(cacheline_dirty) state <= trans;
        else if(fencei_nums == NUM_BLOCKS) state <= trans_end;
      end
      trans:begin
        if(bvalid && bready)begin
          if(fencei_nums == NUM_BLOCKS)
            state <= trans_end;
          else
            state <= trans_begin;
        end
      end
      trans_end:begin
        state <= idle;
      end
      default:begin
        state <= idle;
      end
    endcase
  end
end

always_ff@(posedge i_clock)begin
  if(i_reset) arvalid <= 0;
  else begin
    if(state == idle && !hit && i_valid && !(i_wen && cache[index].dirty) || state == write_mem && o_axi.bvalid)
      arvalid <= 1;
    else if(arvalid && arready)
      arvalid <= 0;
  end
end
always_ff@(posedge i_clock)begin
  if(i_reset) awvalid <= 0;
  else begin
    if(state == idle && !hit && i_wen && cache[index].dirty || fencei_state == trans_begin && cacheline_dirty)
      awvalid <= 1;
    else if(awvalid && awready)
      awvalid <= 0;
  end
end
always_ff@(posedge i_clock)begin
  if(i_reset) wvalid <= 0;
  else begin
    if(state == idle && i_valid && !hit && i_wen || fencei_state == trans_begin && cacheline_dirty)
      wvalid <= 1;
    else if(wlast && wvalid && wready)
      wvalid <= 0;
  end
end
always_ff@(posedge i_clock)begin
  for(int i=0; i<DATA_PER_CACHELINE; i++)begin
    if(state == read_mem && o_axi.rvalid && read_index == i)
      cache[index].data[i*32+:32] <= o_axi.rdata;
    else if(i_valid && i_wen && offset == i && cache[index].valid[i] && hit)begin
      for(int k=0; k<4; k++)begin
        if(i_wmask[k])
          cache[index].data[i*32+k*8+:8] <= i_wdata[k*8+:8];
      end
    end
  end
end
always_ff@(posedge i_clock)begin
  if(i_reset)begin
    for(int i=0; i<NUM_SETS; i++)
      cache[i].valid <= 0;
  end
  else begin
    for(int i=0; i<NUM_SETS; i++)begin
      if(i_valid && state == idle && !hit && index == i)
        cache[i].valid <= 0;
      else if(index == i) begin
        for(int j=0; j<DATA_PER_CACHELINE; j++)begin
          if(state == read_mem && o_axi.rvalid && read_index == j)begin
            cache[i].valid[j] <= 1;
          end
        end
      end
    end
  end
end
always_ff@(posedge i_clock)begin
  if(i_reset)begin
    for(int i=0; i<NUM_SETS; i++)
      cache[i].dirty <= 0;
  end
  else begin
    for(int i=0; i<NUM_SETS; i++)begin
      if(state == idle && !hit && index == i)
        cache[i].dirty <= 0;
      else if(i_valid && hit && i_wen)begin
        cache[i].dirty <= 1;
      end
    end
  end
end
always_ff@(posedge i_clock)begin
  for(int i=0; i<NUM_SETS; i++)begin
    if(state == idle && !hit && index == i)
      cache[i].tag <= tag;
  end
end

logic [DATA_OFFSET_WIDTH-1:0] read_index, write_index;
always_ff@(posedge i_clock)begin
  if(i_reset || rlast) read_index <= 0;
  else if(arvalid) read_index <= offset;
  else if(state == read_mem && rvalid) read_index <= read_index + 1;
end
always_ff@(posedge i_clock)begin
  if(i_reset || wlast && wready) write_index <= 0;
  else if(awvalid) write_index <= 0;
  else if(state == write_mem && wvalid && wready) write_index <= write_index + 1;
end


logic [31:0] axi_wdata;

logic arvalid, arready, rvalid, rready, rlast;
logic awvalid, wvalid, awready, wready, wlast, bvalid, bready;
logic [1:0] rresp, bresp;
logic [3:0] wstrb;
logic [31:0] awaddr, araddr;
assign rready = 1;
assign bready = 1;
assign axi_wdata = cache[index].data[write_index*32+:32];
assign wlast = write_index == DATA_PER_CACHELINE-1;
assign wstrb = 4'b1111;
assign awaddr = {cache[index].tag, (32-TAG_WIDTH)'(0)};
assign araddr = addr;

assign o_axi.araddr = araddr;
assign o_axi.arvalid = arvalid;
assign arready = o_axi.arready;
assign o_axi.arid = 0;
assign o_axi.arlen = 8'(DATA_PER_CACHELINE-1);
assign o_axi.arsize = 3'b010;
assign o_axi.arburst = 2'b10;

assign rvalid = o_axi.rvalid;
assign rresp = o_axi.rresp;
assign o_axi.rready = rready;
assign rlast = o_axi.rlast;

assign o_axi.awaddr = awaddr;
assign o_axi.awvalid = awvalid;
assign o_axi.wvalid = wvalid;
assign awready = o_axi.awready;
assign wready = o_axi.wready;
assign o_axi.wdata = axi_wdata;
assign o_axi.wlast = wlast;
assign o_axi.wstrb = wstrb;
assign o_axi.awid = 0;
assign o_axi.awlen = 8'(DATA_PER_CACHELINE-1);
assign o_axi.awsize = 3'b010;
assign o_axi.awburst = 2'b01;

assign o_axi.bready = bready;
assign bvalid = o_axi.bvalid;
assign bresp = o_axi.bresp;
endmodule
