module ysyx_24110006_CSR(
  input i_clock,
  input i_reset,
  input i_exception,
  input [1:0] i_csr_t,
  input [11:0] i_csr_r,
  input [11:0] i_csr_w,
  input [31:0] i_pc,
  input [31:0] i_wdata,
  input [3:0] i_mcause,
  input i_mret,
  output [31:0] o_rdata,
  output [31:0] o_upc,
  input i_valid
);
localparam MSTATUS = 2'b00;
localparam MTVEC = 2'b01;
localparam MEPC = 2'b10;
localparam MCAUSE = 2'b11;
/* localparam MVENDORID = 3'b100; */
/* localparam MARCHID = 3'b101; */

localparam MRET = 2'b00;
localparam CSRW = 2'b01;
localparam ECALL = 2'b11;

reg[31:0] csr[4];
reg[1:0] index_r, index_w;

always@(*)begin
  case(i_csr_r)
    12'h300: index_r = MSTATUS;
    12'h305: index_r = MTVEC;
    12'h341: index_r = MEPC;
    12'h342: index_r = MCAUSE;
    default: index_r = 0;
  endcase
end
always@(*)begin
  case(i_csr_w)
    12'h300: index_w = MSTATUS;
    12'h305: index_w = MTVEC;
    12'h341: index_w = MEPC;
    12'h342: index_w = MCAUSE;
    default: index_w = 0;
  endcase
end
always@(posedge i_clock)begin
  if(i_valid)begin
    if(i_exception)begin
      csr[MCAUSE] <= {28'b0, i_mcause};
      csr[MEPC] <= i_pc;
    end
    else if(i_csr_t[0])begin
      integer i;
      for(i=0; i<4; i=i+1)begin
        if(index_w==i) csr[i] <= i_wdata;
      end
    end
  end
end

assign o_upc = i_exception ? csr[MTVEC] : i_mret ? csr[MEPC] : 0;
assign o_rdata = {32{i_csr_r == 12'hf11}} & 32'h79737978 |
                 {32{i_csr_r == 12'hf12}} & 32'h16fe3b8  |
                 {32{index_r == 'd0}}    & csr[0]       |
                 {32{index_r == 'd1}}    & csr[1]       |
                 {32{index_r == 'd2}}    & csr[2]       |
                 {32{index_r == 'd3}}    & csr[3]       ;
endmodule
