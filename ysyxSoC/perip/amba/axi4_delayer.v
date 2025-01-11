module delayer #(
  parameter WIDTH = 1
)(
  input clock,
  input reset,
  input c_en,
  input d_en,
  input fin,
  input [WIDTH-1:0] in_data,
  output valid,
  output [WIDTH-1:0] out_data
);
localparam r = 32'd10;
localparam s = 32'd8;
localparam COUNT_ADD = s * r;

localparam IDLE = 3'b000;
localparam COUNT = 3'b001;
localparam DELAY = 3'b010;
localparam WAIT = 3'b011;

reg [2:0] state;
reg [31:0] counter;
reg [WIDTH-1:0] data;
always@(posedge clock)begin
  if(reset) state <= IDLE;
  else begin
    case(state)
      IDLE:begin
        if(c_en) state <= COUNT;
      end
      COUNT:begin
        if(d_en)
          state <= DELAY;
      end
      DELAY:begin
        if(counter == 0) state <= WAIT;
      end
      WAIT:begin
        if(fin) state <= IDLE;
      end
      default: state <= IDLE;
    endcase
  end
end
always@(posedge clock)begin
  if(reset) counter <= 0;
  else begin
    if(state == IDLE && c_en || state == COUNT) begin
      counter <= counter + COUNT_ADD;
      if(d_en) counter <= {3'b0, counter[15:3]};
    end
    else if(state == DELAY && counter != 0)
      counter <= counter - 1;
  end
end

always@(posedge clock)
  if(state == COUNT && d_en) data  <= in_data;

assign valid = state == WAIT;
assign out_data = data;

endmodule


module axi4_delayer(
  input         clock,
  input         reset,

  output        in_arready,
  input         in_arvalid,
  input  [3:0]  in_arid,
  input  [31:0] in_araddr,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [3:0]  in_rid,
  output [31:0] in_rdata,
  output [1:0]  in_rresp,
  output        in_rlast,
  output        in_awready,
  input         in_awvalid,
  input  [3:0]  in_awid,
  input  [31:0] in_awaddr,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
                in_bready,
  output        in_bvalid,
  output [3:0]  in_bid,
  output [1:0]  in_bresp,

  input         out_arready,
  output        out_arvalid,
  output [3:0]  out_arid,
  output [31:0] out_araddr,
  output [7:0]  out_arlen,
  output [2:0]  out_arsize,
  output [1:0]  out_arburst,
  output        out_rready,
  input         out_rvalid,
  input  [3:0]  out_rid,
  input  [31:0] out_rdata,
  input  [1:0]  out_rresp,
  input         out_rlast,
  input         out_awready,
  output        out_awvalid,
  output [3:0]  out_awid,
  output [31:0] out_awaddr,
  output [7:0]  out_awlen,
  output [2:0]  out_awsize,
  output [1:0]  out_awburst,
  input         out_wready,
  output        out_wvalid,
  output [31:0] out_wdata,
  output [3:0]  out_wstrb,
  output        out_wlast,
                out_bready,
  input         out_bvalid,
  input  [3:0]  out_bid,
  input  [1:0]  out_bresp
);
assign in_arready = out_arready;
assign out_arvalid = in_arvalid;
assign out_arid = in_arid; 
assign out_araddr = in_araddr; 
assign out_arlen = in_arlen; 
assign out_arsize = in_arsize; 
assign out_arburst = in_arburst;  
assign out_rready = in_rready; 
assign in_rid = out_rid; 
assign in_rresp = out_rresp;

localparam NUMS = 2;
wire [NUMS-1:0] valid;
reg [NUMS-1:0] tasks;
reg [$clog2(NUMS)-1:0] task_index;
reg [$clog2(NUMS)-1:0] delay_index;
wire [31:0] rdata_buffer[NUMS];
reg [31:0] rdata;
reg rvalid;
always@(posedge clock)begin
  if(reset) begin
    task_index <= 0;
    delay_index <= 0;
  end
  else begin
    if(out_rvalid) task_index <= task_index + 1;
    if(in_rvalid && in_rready) delay_index <= delay_index + 1;
  end
end

always@(posedge clock)begin
  if(reset) tasks <= 0;
  else begin
    if(out_rvalid) tasks[task_index] <= 1;
    if(in_rvalid && in_rready) tasks[delay_index] <= 0;
  end
end

genvar i;
generate
  for(i=0; i<NUMS; i=i+1)begin : m_counter
    delayer
    #( .WIDTH(32) )
    m_delayer(
      .clock(clock),
      .reset(reset || in_rlast && in_rvalid && in_rready),
      .c_en(in_arvalid),
      .d_en(out_rvalid && task_index == i),
      .fin(in_rvalid && in_rready),
      .in_data(out_rdata),
      .valid(valid[i]),
      .out_data(rdata_buffer[i])
    );
  end
endgenerate

reg [$clog2(NUMS)-1:0] rdata_index;
always@(*)begin
  if(valid[0]) rdata_index = 0;
  /* else if(valid[1]) rdata_index = 1; */
  /* else if(valid[2]) rdata_index = 2; */
  /* else if(valid[3]) rdata_index = 3; */
  /* else if(valid[4]) rdata_index = 4; */
  /* else if(valid[5]) rdata_index = 5; */
  /* else if(valid[6]) rdata_index = 6; */
  else rdata_index = 1;
end

assign in_rdata = rdata_buffer[rdata_index];
assign in_rvalid = |valid;

wire rlast_valid;
delayer m_rlast(
  .clock(clock),
  .reset(reset),
  .c_en(in_arvalid),
  .d_en(out_rlast && out_rvalid),
  .fin(in_rvalid && in_rready),
  .in_data(out_rlast),
  .valid(in_rlast),
  .out_data(rlast_valid)
);

assign out_awvalid = in_awvalid;
assign out_awid = in_awid;
assign out_awaddr = in_awaddr;
assign out_awlen = in_awlen;
assign out_awsize = in_awsize;
assign out_awburst = in_awburst;
assign out_wvalid = in_wvalid;
assign out_wdata = in_wdata;
assign out_wstrb = in_wstrb;
assign out_wlast = in_wlast;
assign out_bready = in_bready;
assign in_bid = out_bid;
assign in_bresp = out_bresp;
assign in_awready = out_awready;
assign in_wready = out_wready;

wire bvalid_valid;
delayer m_bvalid(
  .clock(clock),
  .reset(reset),
  .c_en(in_awvalid),
  .d_en(out_bvalid),
  .fin(in_bvalid && in_bready),
  .in_data(out_bvalid),
  .valid(in_bvalid),
  .out_data(bvalid_valid)
);

  /* assign in_arready = state == DELAY && read_counter[delay_index] == 0out_arready; */
  /* assign out_arvalid = in_arvalid; */
  /* assign out_arid = in_arid; */
  /* assign out_araddr = in_araddr; */
  /* assign out_arlen = in_arlen; */
  /* assign out_arsize = in_arsize; */
  /* assign out_arburst = in_arburst; */
  /* assign out_rready = in_rready; */
  /* assign in_rvalid = out_rvalid; */
  /* assign in_rid = out_rid; */
  /* assign in_rdata = out_rdata; */
  /* assign in_rresp = out_rresp; */
  /* assign in_rlast = out_rlast; */
  /* assign in_awready = out_awready; */
  /* assign out_awvalid = in_awvalid; */
  /* assign out_awid = in_awid; */
  /* assign out_awaddr = in_awaddr; */
  /* assign out_awlen = in_awlen; */
  /* assign out_awsize = in_awsize; */
  /* assign out_awburst = in_awburst; */
  /* assign in_wready = out_wready; */
  /* assign out_wvalid = in_wvalid; */
  /* assign out_wdata = in_wdata; */
  /* assign out_wstrb = in_wstrb; */
  /* assign out_wlast = in_wlast; */
  /* assign out_bready = in_bready; */
  /* assign in_bvalid = out_bvalid; */
  /* assign in_bid = out_bid; */
  /* assign in_bresp = out_bresp; */

endmodule
