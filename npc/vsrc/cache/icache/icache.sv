`include "common_config.sv"
module ysyx_24110006_ICACHE#(
    parameter NUM_BLOCKS = 64,
    parameter NUM_WAYS = 1,
    parameter INSTS_PER_CACHELINE = 4,
    parameter BTB_SETS = 32
  )(
  input i_clock,
  input i_reset,
  output [31:0] o_inst,
  output [31:0] o_pc,
  input i_fencei,
  input [31:0] i_upc,
  input i_busy,
  input [31:0] i_pc,
  output o_predict,
  input i_predict_err,
  input i_btb_update,
  if_pipeline_vr.out o_vr,

  input i_flush,
  output o_exception,
  output [3:0] o_mcause,
  if_axi_read.master o_axi
  
);

`ifndef CONFIG_YOSYS
reg hit_counter;
reg miss_counter;
reg [31:0] miss_time;
always@(posedge i_clock)begin
  if(i_reset) begin
    hit_counter <= 0;
    miss_counter <= 0;
  end
  else begin
    if(state == idle_t && hit) hit_counter <= 1;
    else if(state == idle_t && !hit) miss_counter <= 1;
    else begin
      hit_counter <= 0;
      miss_counter <= 0;
    end
  end
end

always@(posedge i_clock)begin
  if(i_reset) miss_time <= 0;
  else begin
    if(state == idle_t && !hit || state == axi_t) miss_time <= miss_time+1;
    else if(o_vr.valid) miss_time <= 0;
  end
end

reg rlast;
always@(posedge i_clock)
  rlast <= o_axi.rlast;
`endif
localparam BTB_TAG_BEGIN = $clog2(BTB_SETS)+2;
localparam BTB_INDEX_WIDTH = $clog2(BTB_SETS);
reg [31:BTB_TAG_BEGIN] btb_tag[BTB_SETS];
reg [31:2] btb_target[BTB_SETS];
always@(posedge i_clock)begin
  if(i_reset) begin
    integer i;
    for (i=0; i<BTB_SETS; i=i+1)
      btb_tag[i] <= 0;
  end
  else if(i_btb_update) begin
    integer i;
    for (i=0; i<BTB_SETS; i=i+1)begin
      btb_tag[i] <= i_pc[BTB_INDEX_WIDTH+2-1:2] == i ? i_pc[31:BTB_TAG_BEGIN] : btb_tag[i];
      btb_target[i] <= i_pc[BTB_INDEX_WIDTH+2-1:2] == i ? i_upc[31:2] : btb_target[i];
    end
  end
end
wire btb_hit = pc[31:BTB_TAG_BEGIN] == btb_tag[pc[BTB_INDEX_WIDTH+2-1:2]];
wire [31:0] btb_pc = {btb_target[pc[BTB_INDEX_WIDTH+2-1:2]], 2'b0};
reg predict;
always@(posedge i_clock)
  if(inst_valid & (o_vr.ready | ~busy)) predict <= btb_hit;
assign o_predict = predict;
wire [31:0] need_plus_pc;
wire [31:0] pc_plus_4;
assign need_plus_pc = i_predict_err && i_flush ? i_pc : pc;
assign pc_plus_4 = need_plus_pc + 4;

reg [31:0] pc;
reg [31:2] pc1;
localparam MROM = 32'h20000000;
localparam FLASH = 32'h30000000;
`ifdef CONFIG_YSYXSOC
  localparam PC = FLASH;
`else
  localparam PC = 32'h80000000;
`endif
wire busy = o_vr.valid && !o_vr.ready;
always@(posedge i_clock)begin
  if(i_reset) pc <= PC;
  else if(i_flush) begin
      pc <= (i_predict_err | i_fencei) ? pc_plus_4 : i_upc;
  end
  else if(inst_valid & (o_vr.ready | ~busy)) begin
      pc <= btb_hit ? btb_pc : pc_plus_4;
  end
end
always@(posedge i_clock)
  if(inst_valid & (o_vr.ready | ~busy)) pc1 <= pc[31:2];
assign o_pc = {pc1, 2'b0};
localparam BLOCK_SIZE = INSTS_PER_CACHELINE * 4;
localparam NUM_SETS = NUM_BLOCKS / NUM_WAYS;
localparam INDEX_WIDTH = $clog2(NUM_SETS);
localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);
localparam TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;
localparam DATA_WIDTH = BLOCK_SIZE*8;
localparam INST_OFFSET_WIDTH = $clog2(INSTS_PER_CACHELINE);

/* localparam AXI_BURST_LEN = 8'd($clog2(INSTS_PER_CACHELINE)); */

wire [TAG_WIDTH-1:0] tag = pc[31 -: TAG_WIDTH];
wire [INDEX_WIDTH-1:0] index = pc[OFFSET_WIDTH +: INDEX_WIDTH];
wire [OFFSET_WIDTH-1:0] offset = pc[OFFSET_WIDTH-1:0];


wire [INST_OFFSET_WIDTH-1:0] which_inst = pc[INST_OFFSET_WIDTH+1:2];
wire [TAG_WIDTH-1:0] cache_tag = araddr[31 -: TAG_WIDTH];
wire [INDEX_WIDTH-1:0] cache_index = araddr[OFFSET_WIDTH +: INDEX_WIDTH];

reg [TAG_WIDTH-1:0] tag_array [NUM_SETS];
reg [INSTS_PER_CACHELINE-1:0] valid_array [NUM_SETS];
reg [DATA_WIDTH-1:0] cache_array [NUM_SETS];

logic [NUM_SETS-1:0] indexs;
always@(*)begin
  integer i;
  for(i=0; i<NUM_SETS; i=i+1)
    indexs[i] = index == i;
end
logic valid_ok;
logic tag_ok;
always@(*)begin
  integer i;
  valid_ok = 0;
  for(i=0; i<NUM_SETS; i=i+1)begin
    integer j;
    for(j=0; j<INSTS_PER_CACHELINE; j=j+1)begin
      valid_ok = valid_ok | indexs[i] & (which_inst == j) & valid_array[i][j];
    end
  end
end

always@(*)begin
  integer i;
  tag_ok = 0;
  for(i=0; i<NUM_SETS; i=i+1)begin
    tag_ok = tag_ok | indexs[i] & (tag_array[i] == tag);
  end
end

wire hit = valid_ok & tag_ok;
wire inst_valid = ((state == idle_t) | (state == axi_t)) & hit & ~i_flush | (state == direct_t) & rvalid;
wire is_sram = pc[31:24] == 8'h0f;

localparam idle_t = 3'b000;
localparam axi_t = 3'b001;
localparam direct_t = 3'b010;
localparam axi_flush_t = 3'b011;
localparam direct_flush_t = 3'b100;
localparam ready_t = 3'b101;
reg [2:0] state;

always@(posedge i_clock)begin
  if(i_reset) state <= idle_t;
  else begin
    case(state)
      idle_t:begin
        if(~hit & ~i_flush & (o_vr.ready | ~busy)) begin
          if(~is_sram) state <= axi_t;
          else state <= direct_t;
        end
      end
      axi_t:begin
        if(o_axi.rlast) state <= ready_t;
        else if(i_flush) state <= axi_flush_t;
      end
      direct_t:begin
        if(o_axi.rvalid) state <= idle_t;
        else if(i_flush) state <= direct_flush_t;
      end
      axi_flush_t:begin
        if(o_axi.rlast) state <= idle_t;
      end
      direct_flush_t:begin
        if(o_axi.rvalid) state <= idle_t;
      end
      ready_t:begin
        state <= idle_t;
      end
      default:begin
        state <= idle_t;
      end
    endcase
  end
end

always@(posedge i_clock)begin
  if(i_reset || i_flush) o_vr.valid <= 0;
  else if(inst_valid) begin
    o_vr.valid <= 1;
  end
  else if(o_vr.valid && o_vr.ready)begin
    o_vr.valid <= 0;
  end
end

reg [31:0] inst;
reg [INST_OFFSET_WIDTH-1:0]burst_counter;
assign o_inst = inst;

wire update_reg;

assign o_exception = (pc[1:0] != 2'b00) | (rresp != 0);
assign o_mcause = rresp != 0 ? 1 : 0;

logic [31:0] cache_inst;
always@(*)begin
  integer i;
  cache_inst = 0;
  for(i=0; i<NUM_SETS;i=i+1)begin
    integer j;
    for(j=0; j<INSTS_PER_CACHELINE; j=j+1)begin
      cache_inst = cache_inst | ({32{indexs[i] & (offset[OFFSET_WIDTH-1:2] == j)}} & cache_array[i][32*j +:32]);
    end
  end
end

always@(posedge i_clock)begin
  if(((state == idle_t) | (state == axi_t)) & hit & (o_vr.ready | ~busy))begin
    inst <= cache_inst;
  end
  else if(state == direct_t & rvalid)
    inst <= o_axi.rdata;
end

always@(posedge i_clock)begin
  if(i_reset || i_fencei) begin
    integer i;
    for(i=0; i<NUM_SETS; i++)begin
      valid_array[i] <= 0;
    end
  end
  else if(arvalid & arready & i_busy)begin
    integer i;
    for(i=0; i<NUM_SETS; i=i+1)begin
      if(cache_index==i) begin
        valid_array[i] <= 0;
        tag_array[i] <= tag;
      end
    end
  end
  else begin
    if(state == axi_t & rvalid & i_busy)begin
      integer i;
      for(i=0; i<NUM_SETS; i=i+1)begin
        if(cache_index==i)begin
          integer j;
          for(j=0; j<INSTS_PER_CACHELINE; j=j+1)begin
            if(burst_counter==j)begin
              cache_array[i][j*32 +: 32] <= o_axi.rdata;
              valid_array[i][j] <= 1;
            end
          end
        end
      end
    end
  end
end

wire cache_miss = (state == idle_t) & ~hit & ~i_flush;
wire axi_free = (o_vr.ready || !busy);
always@(posedge i_clock)begin
  if(i_reset) arvalid <= 0;
  else if(~arvalid & cache_miss & axi_free) arvalid <= 1;
  else if(arvalid & o_axi.arready) arvalid <= 0;
end

always@(posedge i_clock)begin
  if(i_reset || o_axi.rlast) burst_counter <= 0;
  else if(arvalid) burst_counter <= pc[INST_OFFSET_WIDTH+1:2];
  else if(state == axi_t && rvalid) burst_counter <= burst_counter + 1;
end

reg arvalid;
wire arready;
wire rvalid;
wire rready = 1;
wire [1:0] rresp;
reg [31:0] araddr;

always@(posedge i_clock)begin
  if(~arvalid & (state == idle_t & ~hit & ~i_flush) & (o_vr.ready | ~busy)) araddr <= pc;
end
assign o_axi.araddr = araddr;
assign o_axi.arvalid = arvalid;
assign arready = o_axi.arready;
assign o_axi.arid = 0;
assign o_axi.arlen = is_sram ? 0 : 8'(INSTS_PER_CACHELINE-1);
assign o_axi.arsize = 3'b010;
assign o_axi.arburst = is_sram ? 0 : 2'b10;

assign rvalid = o_axi.rvalid;
assign rresp = o_axi.rresp;
assign o_axi.rready = rready;

endmodule
