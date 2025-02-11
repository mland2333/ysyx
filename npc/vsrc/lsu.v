/* import "DPI-C" function int pmem_read(input int raddr); */
/* import "DPI-C" function void pmem_write( */
/*   input int waddr, input int wdata, input byte wmask); */
/**/
`include "common_config.v"
module ysyx_24110006_LSU(
  input i_clock,
  input i_reset,
  input i_ren,
  input i_wen,
  input[31:0] i_wdata,
  input[3:0] i_wmask,
  input[2:0] i_read_t,
  input [4:0] i_reg_rd,
  input [1:0] i_csr_t,
  input i_result_t,
  input i_reg_wen,
  input [31:0] i_result,
  output [1:0] o_csr_t,
  output o_reg_wen,
  output [31:0] o_result,
  output [4:0] o_reg_rd,
  input i_jump,
  output o_jump,
  input [31:0] i_pc,
  output [31:0] o_pc,
  output o_ren,
  input [`BRANCH_MID] i_branch_mid,   
  input [11:0] i_csr,
  output [11:0] o_csr,
  input i_exception,
  output o_exception,
  input [3:0] i_mcause,
  output [3:0] o_mcause,
  input i_valid,
  output reg o_valid,
  input i_ready,
  output o_ready,
  input i_flush,
  input [31:0] i_upc,
  output [31:0] o_upc,
  output o_branch,
`ifdef CONFIG_BTB
  input i_predict,
  output o_predict,
  output o_predict_err,
  output o_btb_update,
`endif
`ifdef CONFIG_SIM
  input [6:0] i_op,
  output [6:0] o_op,
  output o_wen,
  output [31:0] o_addr,
  output o_sim_branch,
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
  input [1:0] i_axi_rresp,
  output o_axi_rready,
  input o_axi_rlast,
  input [3:0] o_axi_rid,

  output [31:0] o_axi_awaddr,
  output o_axi_awvalid,
  input i_axi_awready,
  output [3:0] o_axi_awid,
  output [7:0] o_axi_awlen,
  output [2:0] o_axi_awsize,
  output [1:0] o_axi_awburst,

  output [31:0] o_axi_wdata,
  output [3:0] o_axi_wstrb,
  output o_axi_wvalid,
  input i_axi_wready,
  output o_axi_wlast,

  input [1:0] i_axi_bresp,
  input i_axi_bvalid,
  output o_axi_bready,
  input [3:0] i_axi_bid

);

reg ren;
reg wen;
reg [31:0] addr;
reg [31:0] wdata;
reg [3:0] wmask;
reg [2:0] read_t;
reg [31:0] result;
/* reg [3:0] alu_t; */
reg [4:0] reg_rd;
reg result_t;
reg reg_wen;
reg [1:0] csr_t;
wire mem_valid = ren&&rvalid&&rready || wen&&bvalid&&bready;
wire [31:0] i_addr = i_result;
wire update_reg;

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(!(i_wen||i_ren)&&i_valid &&o_ready && !i_flush|| mem_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end
always@(posedge i_clock)begin
  if(i_reset || i_flush) o_ready <= 1;
  else if(o_ready && !(i_wen||i_ren)) o_ready <= 1;
  else if(o_ready && i_valid && (i_wen || i_ren)) o_ready <= 0;
  else if(!o_ready && mem_valid) o_ready <= 1;
end

assign update_reg = !i_reset && i_valid && o_ready && !i_flush;
reg exception;
always@(posedge i_clock)begin
  if(update_reg)
    exception <= i_exception;
end
assign o_exception = exception | my_exception;
reg [3:0] mcause;
always@(posedge i_clock)begin
  if(update_reg)
    mcause <= i_mcause;
end
assign o_mcause = exception ? mcause : my_mcause;
/* wire load_addr_misaligned = ren & (addr[1:0] != 2'b0) & (read_t == 3'b010) | (addr[0] != 0) & read_t[0]; */
/* wire store_addr_misaligned = wen && (addr[1:0] != 2'b0) & (wmask == 4'b1111) | (addr[0] != 0) & (wmask == 4'b0011); */
wire load_addr_misaligned = 0;
wire store_addr_misaligned = 0;
wire my_exception = load_addr_misaligned | store_addr_misaligned;
wire [3:0] my_mcause = ({4{load_addr_misaligned}} & 4'd4) |
                       ({4{store_addr_misaligned}} & 4'd6);

always@(posedge i_clock)begin
  if(i_reset) rdata <= 0;
  else if(rvalid&&rready) rdata <= rdata0;
end

always@(posedge i_clock)begin
  if(update_reg) ren <= i_ren;
end
assign o_ren = ren;

reg [31:0] upc;
always@(posedge i_clock)begin
  if(update_reg) upc <= i_upc;
end
assign o_upc = upc;
`ifdef CONFIG_SIM

reg [6:0] op;
always@(posedge i_clock)begin
  if(update_reg) op <= i_op;
end
assign o_op = op;
always@(posedge i_clock)begin
  if(update_reg) wen <= i_wen;
end
assign o_wen = wen;
assign o_addr = addr;
assign o_sim_branch = branch;
`endif

reg jump;
always@(posedge i_clock)begin
  if(update_reg) jump <= i_jump;
end
assign o_jump = jump;
reg [31:0] pc;
always@(posedge i_clock)begin
  if(update_reg) pc <= i_pc;
end
assign o_pc = pc;

reg [11:0] csr;
always@(posedge i_clock)begin
  if(update_reg)
    csr <= i_csr;
end
assign o_csr = csr;
reg [`BRANCH_MID] branch_mid;
always@(posedge i_clock)begin
  if(update_reg)
    branch_mid <= i_branch_mid;
end
`ifdef CONFIG_BTB
reg predict;
always@(posedge i_clock)begin
  if(update_reg)
    predict <= i_predict;
end
assign o_predict = predict;
assign o_predict_err = predict && !branch;
assign o_btb_update = !predict && branch_mid[`BRANCH_BACK];
`endif
always@(posedge i_clock)begin
  if(update_reg)begin
    ren <= i_ren;
    wen <= i_wen;
    addr <= i_addr;
    wdata <= i_wdata;
    wmask <= i_wmask;
    read_t <= i_read_t;
    reg_rd <= i_reg_rd;
    result <= i_result;
    result_t <= i_result_t;
    reg_wen <= i_reg_wen;
    csr_t <= i_csr_t;
  end
end
assign o_reg_wen = reg_wen;
assign o_reg_rd = reg_rd;
assign o_csr_t = csr_t;
wire zero = branch_mid[`ZERO];
wire cmp = branch_mid[`CMP];
wire branch = branch_mid[`BEQ] & zero | branch_mid[`BNE] & ~zero | branch_mid[`BLT] & cmp | branch_mid[`BGE] & ~cmp;
`ifdef CONFIG_BTB
  assign o_branch = (predict ^ branch) & (branch_mid[`BRANCH]);
`else
  assign o_branch = branch;
`endif
reg [31:0] o_rdata;
assign o_result = result_t ? o_rdata : result;

reg[31:0] rdata, rdata0;
reg[31:0] wdata0;
reg[3:0] wmask0;

always@(*)begin
  case(addr[1:0])
    2'b00:begin
      rdata0 = i_axi_rdata;
    end
    2'b01:begin
      rdata0 = {8'b0, i_axi_rdata[31:8]};
    end
    2'b10:begin
      rdata0 = {16'b0, i_axi_rdata[31:16]};
    end
    2'b11:begin
      rdata0 = {24'b0, i_axi_rdata[31:24]};
    end
  endcase
end

always @(*) begin
  case (read_t)
    3'b000:  o_rdata = {{24{rdata[7]}}, rdata[7:0]};
    3'b001:  o_rdata = {{16{rdata[15]}}, rdata[15:0]};
    3'b010:  o_rdata = rdata;
    3'b100:  o_rdata = {24'b0, rdata[7:0]};
    3'b101:  o_rdata = {16'b0, rdata[15:0]};
    default: o_rdata = rdata;
  endcase
end


always@(*)begin
  if(wen)begin
    case(addr[1:0])
      2'b00:begin
        wdata0 = wdata;
        wmask0 = {wmask};
      end
      2'b01:begin
        wdata0 = {wdata[23:0], wdata[31:24]};
        wmask0 = {wmask[2:0], 1'b0};
      end
      2'b10:begin
        wdata0 = {wdata[15:0], wdata[31:16]};
        wmask0 = {wmask[1:0], 2'b0};
      end
      2'b11:begin
        wdata0 = {wdata[7:0], wdata[31:8]};
        wmask0 = {wmask[0], 3'b0};
      end
    endcase
  end
  else begin
    wdata0 = 0;
    wmask0 = 0;
  end
end

reg arvalid;
wire arready;

wire rvalid;
reg rready;
wire [1:0] rresp;

reg awvalid;
wire awready;

reg wvalid;
wire wready;

wire [1:0] bresp;
wire bvalid;
reg bready;

assign o_axi_araddr = addr;
assign o_axi_arvalid = arvalid;
assign arready = i_axi_arready;
assign o_axi_arid = 0;
assign o_axi_arlen = 0;
assign o_axi_arsize = i_read_t[1] ? 3'b010 : i_read_t[0] ? 3'b001 : 3'b000;
assign o_axi_arburst = 0;

assign rvalid = i_axi_rvalid;
assign rresp = i_axi_rresp;
assign o_axi_rready = rready;

assign o_axi_awaddr = addr;
assign o_axi_awvalid = awvalid;
assign awready = i_axi_awready;
assign o_axi_awid = 0;
assign o_axi_awlen = 0;
assign o_axi_awsize = wmask == 4'b0011 ? 3'b001 : wmask == 4'b1111 ? 3'b010 : 3'b000;
assign o_axi_awburst = 0;

assign o_axi_wdata = wdata0;
assign o_axi_wstrb = wmask0;
assign o_axi_wvalid = wvalid;
assign wready = i_axi_wready;
assign o_axi_wlast = 1;

assign bresp = i_axi_bresp;
assign bvalid = i_axi_bvalid;
assign o_axi_bready = bready;

always@(posedge i_clock) begin
  if(i_reset) arvalid <= 0;
  else if(update_reg && !arvalid && i_ren) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

always@(posedge i_clock)begin
  /* if(i_reset) rready <= 0; */
  /* else if(rvalid && !rready && count == 0) */
  /*   rready <= 1; */
  /* else if(rvalid && rready) */
  /*   rready <= 0; */
  rready <= 1;
end

always@(posedge i_clock) begin
  if(i_reset) awvalid <= 0;
  else if(update_reg && !awvalid && i_wen) awvalid <= 1;
  else if(awvalid && awready && wvalid && wready) awvalid <= 0;
end

always@(posedge i_clock) begin
  if(i_reset) wvalid <= 0;
  else if(update_reg && !wvalid && i_wen) wvalid <= 1;
  else if(awvalid && awready && wvalid && wready) wvalid <= 0;
end

always@(posedge i_clock)begin
  /* if(i_reset) bready <= 0; */
  /* else if(bvalid && !bready && count == 0) */
  /*   bready <= 1; */
  /* else if(bvalid && bready) */
  /*   bready <= 0; */
  bready <= 1;
end


endmodule
