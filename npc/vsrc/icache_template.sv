module ysyx_24110006_ICACHE_TEMPLATE #(
    parameter NUM_BLOCKS = 4,
    parameter NUM_WAYS = 1,
    parameter BLOCK_SIZE = 8
  )(
  input i_clock,
  input i_reset,
  input [31:0] i_pc,
  output [31:0] o_inst,

  input i_valid,
  output reg o_valid,
  
  output [31:0] o_axi_araddr,
  output o_axi_arvalid,
  input i_axi_arready,
  output [3:0] o_axi_arid,
  output [7:0] o_axi_arlen,
  output [2:0] o_axi_arsize,
  output [1:0] o_axi_arburst,

  input [31:0] i_axi_rdata,
  input i_axi_rvalid,
  output o_axi_rready,
  input [1:0] i_axi_rresp,
  input [3:0] i_axi_rid,
  input i_axi_rlast
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
    if(state == judge_t && hit) hit_counter <= 1;
    else if(state == judge_t && !hit) miss_counter <= 1;
    else begin
      hit_counter <= 0;
      miss_counter <= 0;
    end
  end
end

always@(posedge i_clock)begin
  if(i_reset) miss_time <= 0;
  else begin
    if(o_valid) miss_time <= 0;
    else if(state == judge_t && !hit || state == axi_t) miss_time <= miss_time+1;
  end
end

reg rlast;
always@(posedge i_clock)
  rlast <= i_axi_rlast;
`endif

reg [31:0] pc;
reg [31:0] inst;
reg [7:0] burst_counter;
assign o_inst = inst;

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(state == judge_t && hit || state == ready_t || state == direct_t && rvalid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    pc <= i_pc;
end
wire is_sram = i_pc[31:24] == 8'h0f;

localparam NUM_SETS = NUM_BLOCKS / NUM_WAYS;
localparam INDEX_WIDTH = $clog2(NUM_SETS);
localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);
localparam TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;
localparam DATA_WIDTH = BLOCK_SIZE*8;
localparam LRU_WIDTH = NUM_WAYS == 1 ? 0 : $clog2(NUM_WAYS) - 1;
wire [TAG_WIDTH-1:0] tag = pc[31 -: TAG_WIDTH];
wire [INDEX_WIDTH-1:0] index = (INDEX_WIDTH > 0) ? pc[OFFSET_WIDTH +: INDEX_WIDTH] : 0;
wire [OFFSET_WIDTH-1:0] offset = pc[OFFSET_WIDTH-1:0];

wire [31:0]data_out[NUM_WAYS];
wire [NUM_WAYS-1:0] hit_ways;
reg [NUM_WAYS:0] replace[NUM_SETS];
/* reg [LRU_WIDTH:0] lru[NUM_BLOCKS]; */

genvar i;
generate
  for(i=0; i<NUM_WAYS; i=i+1)begin:icache
    reg[TAG_WIDTH-1:0] tag_array[NUM_SETS];
    reg valid_array[NUM_SETS];
    reg [DATA_WIDTH-1:0] cache_array[NUM_SETS];
    always@(posedge i_clock)begin
      if(i_reset) valid_array[i] <= 0;
    end
    always@(posedge i_clock)begin
      if(i_reset) begin
        integer j;
        for(j=0; j<NUM_SETS; j=j+1)begin
          valid_array[j] <= 0;
        end
      end
      else begin
        if(state == axi_t && rvalid && replace[index][i])begin
          cache_array[index][burst_counter*32 +: 32] <= i_axi_rdata;
          valid_array[index] = 1;
          tag_array[index] = tag;
        end
      end
    end
    assign data_out[i] = cache_array[index][offset*8 +: 32];
    assign hit_ways[i] = valid_array[index] && tag_array[index] == tag;

  end
endgenerate

wire hit = |hit_ways;

/* always@(posedge i_clock)begin */
/*   if(i_reset)begin */
/*     integer i, j; */
/*     for(i = 0; i < NUM_SETS; i = i + 1)begin */
/*       for(j = 0; j < NUM_WAYS; j = j + 1)begin */
/*         lru[i*NUM_SETS][j] <= j; */
/*       end */
/*     end */
/*   end */
/*   else begin */
/*     if(state == judge_t && !hit)begin */
/*       integer i; */
/*       for(i=0; i<NUM_WAYS; i=i+1)begin */
/*         integer lru_index = index*NUM_SETS+i; */
/*         if(hit_ways[i]) begin */
/*           lru[lru_index] <= 0; */
/*         end */
/*         else if(lru[lru_index] != NUM_WAYS-1)begin */
/*           lru[lru_index] <= lru[lru_index] + 1; */
/*         end */
/*       end */
/*     end */
/*   end */
/* end */

/* always@(posedge i_clock)begin */
/*   if(!arvalid && state == judge_t && !hit) begin */
/*     integer m; */
/*     reg [LRU_WIDTH:0] max_count; */
/*     reg [1:0] lru_index; */
/*     max_count = 0; */
/*     lru_index = 0; */
/*     for(m = 0; m < NUM_WAYS; m = m + 1)begin */
/*       if(lru_counter[index][m] > max_count)begin */
/*         max_count = lru_counter[index*NUM_SETS+m]; */
/*         lru_index = m; */
/*       end */
/*     end */
/*     replace[index] = 1 << lru_index; // 将LRU块设置为替换目标 */
/*   end */
/* end */



always@(posedge i_clock)begin
  if(i_reset) begin
    integer j;
    for(j=0; j<NUM_SETS; j=j+1)begin
      replace[j][NUM_WAYS-1] <= 1;
    end
  end
  else if(!arvalid && state == judge_t && !hit)
    if(replace[index][NUM_WAYS-1]) replace[index] <= 1;
    else replace[index] <= {replace[index][NUM_WAYS-1:0],replace[index][NUM_WAYS]};
end

always@(posedge i_clock)begin
  if(state == judge_t && hit || state == ready_t)begin
    integer j;
    for(j = 0; j<NUM_WAYS; j=j+1)begin
      if(hit_ways[j]) inst <= data_out[j];
    end
  end
  else if(state == direct_t && rvalid)
    inst <= i_axi_rdata;
end

/* reg [TAG_WIDTH-1:0] tag_array [NUM_BLOCKS]; */
/* reg [NUM_BLOCKS-1:0] valid_array; */
/* reg [DATA_WIDTH-1:0] cache_array [NUM_BLOCKS]; */
/* reg [NUM_WAYS-1:0] hit_ways; */
/* reg [NUM_WAYS:0] replace; */


reg [2:0] state;

/* typedef enum [2:0] {idle_t, judge_t, axi_t, direct_t, ready_t} state_t; */
localparam idle_t = 3'b000;
localparam judge_t = 3'b001;
localparam axi_t = 3'b010;
localparam direct_t = 3'b011;
localparam ready_t = 3'b100;

always@(posedge i_clock)begin
  if(i_reset) state <= idle_t;
  else begin
    case(state)
      idle_t:begin
        if(i_valid && !is_sram) state <= judge_t;
        else if(i_valid && is_sram) state <= direct_t;
      end
      judge_t:begin
        if(hit) state <= idle_t;
        else state <= axi_t;
      end
      axi_t:begin
        if(i_axi_rlast) state <= ready_t;
      end
      direct_t:begin
        if(rvalid) state <= idle_t;
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
  if(i_reset) arvalid <= 0;
  else if(!arvalid && (i_valid && is_sram || state == judge_t && !hit)) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end


/* always@(posedge i_clock)begin */
/*   if(state == axi_t && rvalid)begin */
/*     integer i; */
/*     integer replace_index; */
/*     for(i=0; i<NUM_WAYS; i=i+1)begin */
/*       replace_index = index * NUM_WAYS + i; */
/*       if(replace[i]) begin */
/*         cache_array[replace_index][burst_counter*32+:32] <= i_axi_rdata; */
/*         valid_array[replace_index] <= 1; */
/*         tag_array[replace_index] <= tag; */
/*       end */
/*     end */
/*   end */
/* end */

always@(posedge i_clock)begin
  if(i_reset || i_axi_rlast) burst_counter <= 0;
  else if(state == axi_t && rvalid) burst_counter <= burst_counter + 1;
end

reg arvalid;
wire arready;
wire rvalid;
wire rready = 1;
wire [1:0] rresp;

assign o_axi_araddr = is_sram ? pc : {pc[31:OFFSET_WIDTH], {(OFFSET_WIDTH){1'b0}}};
assign o_axi_arvalid = arvalid;
assign arready = i_axi_arready;
assign o_axi_arid = 0;
assign o_axi_arlen = is_sram ? 0 : BLOCK_SIZE/4 - 1;
assign o_axi_arsize = 3'b010;
assign o_axi_arburst = is_sram ? 0 : 2'b01;

assign rvalid = i_axi_rvalid;
assign rresp = i_axi_rresp;
assign o_axi_rready = rready;



endmodule
