module ysyx_24110006_CSR(
  input i_clock,
  input i_reset,
  input i_wen,
  input[2:0] i_csr_t,
  input[11:0] i_csr,
  input[31:0] i_pc,
  input[31:0] i_wdata,
  input[31:0] i_mcause,
  output[31:0] o_rdata,
  output[31:0] o_upc,
  input i_valid
);
localparam MSTATUS = 3'b000;
localparam MTVEC = 3'b001;
localparam MEPC = 3'b010;
localparam MCAUSE = 3'b011;
localparam MVENDORID = 3'b100;
localparam MARCHID = 3'b101;

localparam MRET = 3'b000;
localparam CSRW = 3'b001;
localparam ECALL = 3'b011;

reg[31:0] csr[8];
reg[2:0] index;

always@(*)begin
  case(i_csr)
    12'h300: index = MSTATUS;
    12'h305: index = MTVEC;
    12'h341: index = MEPC;
    12'h342: index = MCAUSE;
    12'hf11: index = MVENDORID;
    12'hf12: index = MARCHID;
    default: index = 0;
  endcase
end

always@(posedge i_clock)begin
  if(i_valid && i_wen)begin
    case(i_csr_t)
      ECALL:begin
        csr[MEPC] = i_pc;
        csr[MCAUSE] = i_mcause;
      end
      CSRW:begin
        csr[index] = i_wdata;
      end
      default:begin
      end
    endcase
  end
end

always@(posedge i_clock)
  csr[MVENDORID] = 32'h79737978;
always@(posedge i_clock)
  csr[MARCHID] = 32'h16fe3b6;


assign o_upc = i_csr_t == ECALL ? csr[MTVEC] : i_csr_t == MRET ? csr[MEPC] : 0;
assign o_rdata = csr[index];

endmodule
