module ysyx_24110006_ICACHE(
  input i_clock,
  input i_reset,
  input [31:0] i_pc,
  output [31:0] o_inst,
  output [31:0] o_pc,
  input i_fencei,

  input i_valid,
  output reg o_valid,
`ifdef CONFIG_PIPELINE
  input i_ready,
  output o_ready,
  input i_flush,
  input i_conflict,
  output o_exception,
  output [3:0] o_mcause,
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
