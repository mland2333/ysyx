`ifndef CONFIG_ICACHE_PIPELINE
module ysyx_24110006_ICACHE(
  input i_clock,
  input i_reset,
  input [31:0] i_pc,
  output [31:0] o_inst,
  output [31:0] o_pc,
  input i_fencei,

  input i_valid,
  output reg o_valid,
  output o_exception,
  output [3:0] o_mcause,
`ifdef CONFIG_PIPELINE
  input i_ready,
  output o_ready,
  input i_flush,
`endif

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
    if(state == judge_t && !hit || state == axi_t) miss_time <= miss_time+1;
    else if(o_valid) miss_time <= 0;
  end
end

reg rlast;
always@(posedge i_clock)
  rlast <= i_axi_rlast;
`endif

reg [31:0] pc;
reg [31:0] inst;
reg [1:0] burst_counter;
assign o_inst = inst;
wire inst_valid = state == judge_t && hit || state == ready_t || state == wait_t && rvalid;
wire update_reg;
`ifdef CONFIG_PIPELINE
reg r_flush;
always@(posedge i_clock)begin
  if(i_flush && !inst_valid && !o_ready) r_flush <= 1;
  else if(r_flush && inst_valid) r_flush <= 0;
end

always@(posedge i_clock)begin
  if(i_reset || i_flush || r_flush) o_valid <= 0;
  else if(inst_valid) begin
    o_valid <= 1;
  end
  else if(o_valid && i_ready)begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(i_reset) o_ready <= 1;
  else if(i_valid && o_ready && !i_flush) o_ready <= 0;
  else if((inst_valid || !o_ready && o_valid) && i_ready) o_ready <= 1;
end
assign update_reg = !i_reset && i_valid && o_ready && !i_flush;
assign o_exception = pc[1:0] != 2'b00 || rresp != 0;
assign o_mcause = rresp != 0 ? 1 : 0;
`else
always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(inst_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end
assign update_reg = !i_reset && !o_valid && i_valid;
`endif
always@(posedge i_clock)begin
  if(update_reg)
    pc <= i_pc;
end

assign o_pc = pc;
wire is_sram = i_pc[31:24] == 8'h0f;

wire [26:0] tag = pc[31:5];
wire [1:0] index = pc[4:3];
wire [2:0] offset = pc[2:0];

reg [26:0] tag_array [4];
reg [3:0] valid_array;
reg [63:0] cache_array [4];

always@(posedge i_clock)begin
  if(i_reset || i_valid && i_fencei) begin
    valid_array <= 0;
  end
  else begin
    if(state == axi_t && rvalid)begin
      cache_array[index][burst_counter*32 +: 32] <= i_axi_rdata;
      valid_array[index] <= 1;
      tag_array[index] <= tag;
    end
  end
end

wire hit = valid_array[index] && tag_array[index] == tag;

always@(posedge i_clock)begin
  if(state == judge_t && hit || state == ready_t)begin
    inst <= cache_array[index][offset*8 +: 32];
  end
  else if(state == wait_t && rvalid)
    inst <= i_axi_rdata;
end

reg [2:0] state;

localparam idle_t = 3'b000;
localparam judge_t = 3'b001;
localparam axi_t = 3'b010;
localparam direct_t = 3'b011;
localparam ready_t = 3'b100;
localparam wait_t = 3'b101;

always@(posedge i_clock)begin
  if(i_reset) state <= idle_t;
  else begin
    case(state)
      idle_t:begin
        if(update_reg && !is_sram) state <= judge_t;
        else if(update_reg && is_sram) state <= direct_t;
      end
      judge_t:begin
        if(hit) state <= idle_t;
        else state <= axi_t;
      end
      axi_t:begin
        if(i_axi_rlast) state <= ready_t;
      end
      direct_t:begin
        state <= wait_t;
      end
      wait_t:begin
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
  else if(!arvalid && (state == direct_t || state == judge_t && !hit)) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

always@(posedge i_clock)begin
  if(i_reset || i_axi_rlast) burst_counter <= 0;
  else if(state == axi_t && rvalid) burst_counter <= burst_counter + 1;
end

reg arvalid;
wire arready;
wire rvalid;
wire rready = 1;
wire [1:0] rresp;

wire in_sram = state == direct_t || state == wait_t;
assign o_axi_araddr = in_sram ? pc : {pc[31:3], 3'b0};
assign o_axi_arvalid = arvalid;
assign arready = i_axi_arready;
assign o_axi_arid = 0;
assign o_axi_arlen = in_sram ? 0 : 1;
assign o_axi_arsize = 3'b010;
assign o_axi_arburst = in_sram ? 0 : 2'b01;

assign rvalid = i_axi_rvalid;
assign rresp = i_axi_rresp;
assign o_axi_rready = rready;

endmodule
`else
`include "common_config.v"
module ysyx_24110006_ICACHE(
  input i_clock,
  input i_reset,
  output [31:0] o_inst,
  output [31:0] o_pc,
  input i_fencei,
  input [31:0] i_upc,
  input i_busy,
`ifdef CONFIG_BTB
  input [31:0] i_pc,
  output o_predict,
  input i_predict_err,
  input i_btb_update,
`endif
  input i_valid,
  output reg o_valid,
  input i_ready,
  output o_ready,

  input i_flush,
  output o_exception,
  output [3:0] o_mcause,

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
    else if(o_valid) miss_time <= 0;
  end
end

reg rlast;
always@(posedge i_clock)
  rlast <= i_axi_rlast;
`endif
`ifdef CONFIG_BTB
  reg [31:3] btb_tag[2];
  reg [31:2] btb_target[2];
  always@(posedge i_clock)begin
    if(i_reset) begin
      btb_tag[0] <= 0;
      btb_tag[1] <= 0;
    end
    else if(i_btb_update) begin
      btb_tag[0] <= i_pc[2] == 0 ? i_pc[31:3] : btb_tag[0];
      btb_target[0] <= i_pc[2] == 0 ? i_upc[31:2] : btb_target[0];

      btb_tag[1] <= i_pc[2] == 1 ? i_pc[31:3] : btb_tag[1];
      btb_target[1] <= i_pc[2] == 1 ? i_upc[31:2] : btb_target[1];
    end
  end
  wire btb_hit = pc[31:3] == btb_tag[pc[2]];
  wire [31:0] btb_pc = {btb_target[pc[2]], 2'b0};
  reg predict;
  always@(posedge i_clock)
    if(inst_valid & (i_ready | ~busy)) predict <= btb_hit;
  assign o_predict = predict;
  wire [31:0] need_plus_pc;
  wire [31:0] pc_plus_4;
  assign need_plus_pc = i_predict_err && i_flush ? i_pc : pc;
  assign pc_plus_4 = need_plus_pc + 4;
`endif 
reg [31:0] pc;
reg [31:2] pc1;
localparam MROM = 32'h20000000;
localparam FLASH = 32'h30000000;
`ifdef CONFIG_YSYXSOC
  localparam PC = FLASH;
`else
  localparam PC = 32'h80000000;
`endif
wire busy = o_valid && !i_ready;
always@(posedge i_clock)begin
  if(i_reset) pc <= PC;
  else if(i_flush) begin
    `ifdef CONFIG_BTB
      pc <= i_predict_err ? pc_plus_4 : i_upc;
    `else
      pc <= i_upc;
    `endif
  end
  else if(inst_valid & (i_ready | ~busy)) begin
    `ifdef CONFIG_BTB
      pc <= btb_hit ? btb_pc : pc_plus_4;
    `else
      pc <= pc + 4;
    `endif
  end
end
always@(posedge i_clock)
  if(inst_valid & (i_ready | ~busy)) pc1 <= pc[31:2];
assign o_pc = {pc1, 2'b0};

/* reg busy; */
/* always@(posedge i_clock)begin */
/*   if(i_reset) busy <= 0; */
/*   else if(o_valid && !i_ready) busy <= 1; */
/*   else if(i_ready) busy <= 0; */
/* end */
wire [26:0] tag = pc[31:5];
wire [1:0] index = pc[4:3];
wire [2:0] offset = pc[2:0];
wire valid = pc[2];
wire [26:0] cache_tag = araddr[31:5];
wire [1:0] cache_index = araddr[4:3];
reg [26:0] tag_array [4];
reg [1:0] valid_array [4];
reg [63:0] cache_array [4];
wire hit = valid_array[index][valid] & (tag_array[index] == tag);
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
        if(~hit & ~i_flush & (i_ready | ~busy)) begin
          if(~is_sram) state <= axi_t;
          else state <= direct_t;
        end
      end
      axi_t:begin
        if(i_axi_rlast) state <= ready_t;
        else if(i_flush) state <= axi_flush_t;
      end
      direct_t:begin
        if(i_axi_rvalid) state <= idle_t;
        else if(i_flush) state <= direct_flush_t;
      end
      axi_flush_t:begin
        if(i_axi_rlast) state <= idle_t;
      end
      direct_flush_t:begin
        if(i_axi_rvalid) state <= idle_t;
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
  if(i_reset || i_flush) o_valid <= 0;
  else if(inst_valid) begin
    o_valid <= 1;
  end
  else if(o_valid && i_ready)begin
    o_valid <= 0;
  end
end

reg [31:0] inst;
reg burst_counter;
assign o_inst = inst;

wire update_reg;

assign o_exception = (pc[1:0] != 2'b00) | (rresp != 0);
assign o_mcause = rresp != 0 ? 1 : 0;

always@(posedge i_clock)begin
  if(((state == idle_t) | (state == axi_t)) & hit & (i_ready | ~busy))begin
    inst <= cache_array[index][offset*8 +: 32];
  end
  else if(state == direct_t & rvalid)
    inst <= i_axi_rdata;
end

always@(posedge i_clock)begin
  if(i_reset || i_valid && i_fencei) begin
    integer i;
    for(i=0; i<4; i++)begin
      valid_array[i] <= 0;
    end
  end
  else if(arvalid & arready & i_busy)begin
    valid_array[cache_index] <= 0;
    tag_array[cache_index] <= tag;
  end
  else begin
    if(state == axi_t & rvalid & i_busy)begin
      cache_array[cache_index][burst_counter*32 +: 32] <= i_axi_rdata;
      valid_array[cache_index][burst_counter] <= 1;
    end
  end
end

wire cache_miss = (state == idle_t) & ~hit & ~i_flush;
wire axi_free = (i_ready || !busy);
always@(posedge i_clock)begin
  if(i_reset) arvalid <= 0;
  else if(~arvalid & cache_miss & axi_free) arvalid <= 1;
  else if(arvalid & i_axi_arready) arvalid <= 0;
end

always@(posedge i_clock)begin
  if(i_reset || i_axi_rlast) burst_counter <= 0;
  else if(arvalid) burst_counter <= pc[2];
  else if(state == axi_t && rvalid) burst_counter <= burst_counter + 1;
end

reg arvalid;
wire arready;
wire rvalid;
wire rready = 1;
wire [1:0] rresp;
reg [31:0] araddr;

always@(posedge i_clock)begin
  if(~arvalid & (state == idle_t & ~hit & ~i_flush) & (i_ready | ~busy)) araddr <= pc;
end
assign o_axi_araddr = araddr;
assign o_axi_arvalid = arvalid;
assign arready = i_axi_arready;
assign o_axi_arid = 0;
assign o_axi_arlen = is_sram ? 0 : 1;
assign o_axi_arsize = 3'b010;
assign o_axi_arburst = is_sram ? 0 : 2'b10;

assign rvalid = i_axi_rvalid;
assign rresp = i_axi_rresp;
assign o_axi_rready = rready;

endmodule
`endif
