`include "common_config.sv"
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
    if(inst_valid & (o_vr.ready | ~busy)) predict <= btb_hit;
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
wire busy = o_vr.valid && !o_vr.ready;
always@(posedge i_clock)begin
  if(i_reset) pc <= PC;
  else if(i_flush) begin
    `ifdef CONFIG_BTB
      pc <= (i_predict_err | i_fencei) ? pc_plus_4 : i_upc;
    `else
      pc <= i_upc;
    `endif
  end
  else if(inst_valid & (o_vr.ready | ~busy)) begin
    `ifdef CONFIG_BTB
      pc <= btb_hit ? btb_pc : pc_plus_4;
    `else
      pc <= pc + 4;
    `endif
  end
end
always@(posedge i_clock)
  if(inst_valid & (o_vr.ready | ~busy)) pc1 <= pc[31:2];
assign o_pc = {pc1, 2'b0};

wire [26:0] tag = pc[31:5];
wire [1:0] index = pc[4:3];
wire [2:0] offset = pc[2:0];
wire valid = pc[2];
wire [26:0] cache_tag = araddr[31:5];
wire [1:0] cache_index = araddr[4:3];
reg [26:0] tag_array [4];
reg [1:0] valid_array [4];
reg [63:0] cache_array [4];
wire index0 = index == 'd0;
wire index1 = index == 'd1;
wire index2 = index == 'd2;
wire index3 = index == 'd3;
wire valid_ok = (index0 & (valid == 'd0) & valid_array[0][0]) |
                (index0 & (valid == 'd1) & valid_array[0][1]) |
                (index1 & (valid == 'd0) & valid_array[1][0]) |
                (index1 & (valid == 'd1) & valid_array[1][1]) |
                (index2 & (valid == 'd0) & valid_array[2][0]) |
                (index2 & (valid == 'd1) & valid_array[2][1]) |
                (index3 & (valid == 'd0) & valid_array[3][0]) |
                (index3 & (valid == 'd1) & valid_array[3][1]) ;
wire tag_ok = (index0 & (tag_array[0] == tag)) |
              (index1 & (tag_array[1] == tag)) |
              (index2 & (tag_array[2] == tag)) |
              (index3 & (tag_array[3] == tag)) ;
/* wire hit = valid_array[index][valid] & (tag_array[index] == tag); */
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
reg burst_counter;
assign o_inst = inst;

wire update_reg;

assign o_exception = (pc[1:0] != 2'b00) | (rresp != 0);
assign o_mcause = rresp != 0 ? 1 : 0;

wire [31:0] cache_inst = ({32{index0 & (offset[2] == 'd0)}} & cache_array[0][0 +:32]) |
                         ({32{index0 & (offset[2] == 'd1)}} & cache_array[0][32+:32]) |
                         ({32{index1 & (offset[2] == 'd0)}} & cache_array[1][0 +:32]) |
                         ({32{index1 & (offset[2] == 'd1)}} & cache_array[1][32+:32]) |
                         ({32{index2 & (offset[2] == 'd0)}} & cache_array[2][0 +:32]) |
                         ({32{index2 & (offset[2] == 'd1)}} & cache_array[2][32+:32]) |
                         ({32{index3 & (offset[2] == 'd0)}} & cache_array[3][0 +:32]) |
                         ({32{index3 & (offset[2] == 'd1)}} & cache_array[3][32+:32]) ;
always@(posedge i_clock)begin
  if(((state == idle_t) | (state == axi_t)) & hit & (o_vr.ready | ~busy))begin
    /* inst <= cache_array[index][offset*8 +: 32]; */
    inst <= cache_inst;
  end
  else if(state == direct_t & rvalid)
    inst <= o_axi.rdata;
end

always@(posedge i_clock)begin
  if(i_reset || i_fencei) begin
    integer i;
    for(i=0; i<4; i++)begin
      valid_array[i] <= 0;
    end
  end
  else if(arvalid & arready & i_busy)begin
    integer i;
    for(i=0; i<4; i=i+1)begin
      if(cache_index==i) begin
        valid_array[i] <= 0;
        tag_array[i] <= tag;
      end
    end
  end
  else begin
    if(state == axi_t & rvalid & i_busy)begin
      integer i;
      for(i=0; i<4; i=i+1)begin
        if(cache_index==i)begin
          integer j;
          for(j=0; j<2; j=j+1)begin
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
  if(~arvalid & (state == idle_t & ~hit & ~i_flush) & (o_vr.ready | ~busy)) araddr <= pc;
end
assign o_axi.araddr = araddr;
assign o_axi.arvalid = arvalid;
assign arready = o_axi.arready;
assign o_axi.arid = 0;
assign o_axi.arlen = is_sram ? 0 : 1;
assign o_axi.arsize = 3'b010;
assign o_axi.arburst = is_sram ? 0 : 2'b10;

assign rvalid = o_axi.rvalid;
assign rresp = o_axi.rresp;
assign o_axi.rready = rready;

endmodule
