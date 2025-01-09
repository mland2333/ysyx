module gpio_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [15:0] gpio_out,
  input  [15:0] gpio_in,
  output [7:0]  gpio_seg_0,
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);

reg [15:0] led;
reg [15:0] sw;
reg ready;
reg [15:0] rdata;
assign in_pready = ready;
always@(posedge clock)begin
  if(in_penable) ready <= 1;
  else if(ready) ready <= 0;
end

always@(posedge clock)begin
  if(reset) led <= 0;
  else begin
    if(in_penable && in_paddr[3:2] == 2'h0)
      led <= in_pwdata[15:0];
  end
end

always@(posedge clock)begin
  if(reset) rdata <= 0;
  else begin
    if(in_penable && !in_pwrite && in_paddr[3:2] == 2'h1)
      rdata <= gpio_in;
  end
end

assign in_prdata = {16'b0, rdata};
assign gpio_out = led;

reg [3:0] seg_in[8];
reg [7:0] seg_out[8];
assign gpio_seg_0 = seg_out[0];
assign gpio_seg_1 = seg_out[1];
assign gpio_seg_2 = seg_out[2];
assign gpio_seg_3 = seg_out[3];
assign gpio_seg_4 = seg_out[4];
assign gpio_seg_5 = seg_out[5];
assign gpio_seg_6 = seg_out[6];
assign gpio_seg_7 = seg_out[7];

reg[7:0] a[16];
always@(*)begin
  a[0] = 8'b00000011;
  a[1] = 8'b10011111;
  a[2] = 8'b00100101;
  a[3] = 8'b00001101;
  a[4] = 8'b10011001;
  a[5] = 8'b01001001;
  a[6] = 8'b01000001;
  a[7] = 8'b00011111;
  a[8] = 8'b00000001;
  a[9] = 8'b00011001;
  a[10] = 8'b00000001;
  a[11] = 8'b00000001;
  a[12] = 8'b00000001;
  a[13] = 8'b00000001;
  a[14] = 8'b00000001;
  a[15] = 8'b00000001;
end

integer i;
always@(posedge clock)begin
  if(reset) begin
    for(i = 0; i < 8; i=i+1)begin
      seg_out[i] <= 0;
    end
  end
  else if(in_penable && in_pwrite && in_paddr[3:2] == 2'b10) begin
    for(i = 0; i < 8; i=i+1)begin
      seg_out[i] <= a[in_pwdata[i*4 +: 4]];
    end
  end
end


endmodule
