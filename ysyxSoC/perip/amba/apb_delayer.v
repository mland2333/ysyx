module apb_delayer(
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

  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

assign in_pready = out_pready;
assign in_prdata = out_prdata;
assign in_pslverr = out_pslverr;

assign out_paddr = in_paddr;
assign out_psel = in_psel;
assign out_penable = in_penable;
assign out_pprot = in_pprot;
assign out_pwrite = in_pwrite;
assign out_pwdata = in_pwdata;
assign out_pstrb = in_pstrb;
/* localparam IDLE = 3'b000; */
/* localparam COUNT = 3'b001; */
/* localparam DELAY = 3'b010; */
/* localparam WAIT = 3'b011; */
/**/
/* localparam r = 32'd10; */
/* localparam s0 = 32'b1; */
/* localparam s = s0 << 3; */
/* localparam COUNT_ADD = s * r; */
/**/
/* reg [2:0] state; */
/* reg [31:0] counter; */
/* always@(posedge clock)begin */
/*   if(reset) state <= IDLE; */
/*   else begin */
/*     case(state) */
/*       IDLE:begin */
/*         if(in_penable) state <= COUNT; */
/*       end */
/*       COUNT:begin */
/*         if(out_pready) */
/*           state <= DELAY; */
/*       end */
/*       DELAY:begin */
/*         if(counter == 0) state <= WAIT; */
/*       end */
/*       WAIT:begin */
/*         state <= IDLE; */
/*       end */
/*       default: state <= IDLE; */
/*     endcase */
/*   end */
/* end */
/* always@(posedge clock)begin */
/*   if(reset) counter <= 0; */
/*   else begin */
/*     if(state == COUNT) begin */
/*       counter <= counter + COUNT_ADD; */
/*       if(out_pready) counter <= {3'b0, counter[15:3]}; */
/*     end */
/*     else if(state == DELAY && counter != 0) */
/*       counter <= counter - 1; */
/*   end */
/* end */
/**/
/* reg [31:0] rdata; */
/* reg pslverr; */
/**/
/* always@(posedge clock) */
/*   if(state == COUNT && out_pready) rdata  <= out_prdata; */
/**/
/* always@(posedge clock) */
/*   if(state == COUNT && out_pready) pslverr <= out_pslverr; */
/**/
/* assign out_paddr   = in_paddr; */
/* assign out_psel    = state == IDLE || state == COUNT ? in_psel : 0; */
/* assign out_penable = state == IDLE || state == COUNT ? in_penable : 0; */
/* assign out_pprot   = state == IDLE || state == COUNT ? in_pprot : 0; */
/* assign out_pwrite  = in_pwrite; */
/* assign out_pwdata  = in_pwdata; */
/* assign out_pstrb   = in_pstrb; */
/* assign in_pready   = state == WAIT ? 1 : 0; */
/* assign in_prdata   = rdata; */
/* assign in_pslverr  = pslverr; */
endmodule
