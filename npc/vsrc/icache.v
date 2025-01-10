module ysyx_24110006_ICACHE(
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

wire [25:0] tag = pc[31:6];
wire [3:0] index = pc[5:2];
wire [1:0] offset = pc[1:0];

reg [25:0] tag_array [16];
reg [15:0] valid_array;
reg [31:0] cache_array [16];

always@(posedge i_clock)begin
  if(i_reset) begin
    valid_array <= 0;
  end
  else begin
    if(state == axi_t && rvalid)begin
      cache_array[index] <= i_axi_rdata;
      valid_array[index] <= 1;
      tag_array[index] <= tag;
    end
  end
end

wire hit = valid_array[index] && tag_array[index] == tag;

always@(posedge i_clock)begin
  if(state == judge_t && hit || state == ready_t)begin
    inst <= cache_array[index];
  end
  else if(state == direct_t && rvalid)
    inst <= i_axi_rdata;
end

reg [2:0] state;

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

reg arvalid;
wire arready;
wire rvalid;
wire rready = 1;
wire [1:0] rresp;

assign o_axi_araddr = pc;
assign o_axi_arvalid = arvalid;
assign arready = i_axi_arready;
assign o_axi_arid = 0;
assign o_axi_arlen = 0;
assign o_axi_arsize = 3'b010;
assign o_axi_arburst = 0;

assign rvalid = i_axi_rvalid;
assign rresp = i_axi_rresp;
assign o_axi_rready = rready;



endmodule
