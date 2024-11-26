import "DPI-C" function void quit();
import "DPI-C" function void difftest();
import "DPI-C" function void diff_skip();
module top(
  input clock,
  input reset,
  output [31:0] reg_wdata
);

wire jump;
wire trap;
wire branch;
wire[31:0] upc, pc;

wire[31:0] inst;
wire[6:0] op;
wire[2:0] func;
wire[4:0] reg_rs1, reg_rs2, reg_rd;
wire[31:0] imm;

wire[31:0] reg_src1, reg_src2;
/* wire[31:0] reg_wdata; */
wire[31:0] csr_src;

wire reg_wen;
wire csr_wen;
wire[31:0] exu_result;
wire[31:0] csr_mcause = 32'd11;
wire[31:0] csr_upc;
wire[11:0] csr = imm[11:0];
wire[2:0] csr_t;
wire[31:0] csr_wdata;

wire mem_ren, mem_wen;
wire[3:0] mem_wmask;
wire[2:0] mem_read_t;
wire[31:0] mem_addr = exu_result;
wire[31:0] mem_wdata = reg_src2;
wire[31:0] mem_rdata;
wire result_t;

assign reg_wdata = result_t ? mem_rdata : exu_result;
assign csr_wdata = exu_result;

wire pc_valid, ifu_valid, idu_valid, exu_valid, lsu_valid;

reg[31:0] npc_upc;
always@(posedge clock)
  npc_upc <= upc;

reg diff;
always@(posedge clock)begin
  if(clint_rvalid || uart_bvalid) diff_skip();
end

always@(posedge clock)begin
  if(ifu_valid && diff) difftest();
end

always@ *
  if(inst == 32'h100073)
    quit();

wire [31:0] ifu_araddr;
wire ifu_arvalid;
wire ifu_arready;
wire [31:0] ifu_rdata;
wire ifu_rvalid;
wire ifu_rready;
wire [1:0] ifu_rresp;

wire [31:0] lsu_araddr;
wire lsu_arvalid;
wire lsu_arready;
wire [31:0] lsu_rdata;
wire lsu_rvalid;
wire lsu_rready;
wire [1:0] lsu_rresp;
wire [31:0] lsu_awaddr;
wire lsu_awvalid;
wire lsu_awready;
wire [31:0] lsu_wdata;
wire [7:0] lsu_wstrb;
wire lsu_wvalid;
wire lsu_wready;
wire [1:0] lsu_bresp;
wire lsu_bvalid;
wire lsu_bready;

wire [31:0] xbar_araddr;
wire xbar_arvalid;
wire xbar_arready;
wire [31:0] xbar_rdata;
wire xbar_rvalid;
wire xbar_rready;
wire [1:0] xbar_rresp;
wire [31:0] xbar_awaddr;
wire xbar_awvalid;
wire xbar_awready;
wire [31:0] xbar_wdata;
wire [7:0] xbar_wstrb;
wire xbar_wvalid;
wire xbar_wready;
wire [1:0] xbar_bresp;
wire xbar_bvalid;
wire xbar_bready;

wire [31:0] sram_araddr;
wire sram_arvalid;
wire sram_arready;
wire [31:0] sram_rdata;
wire sram_rvalid;
wire sram_rready;
wire [1:0] sram_rresp;
wire [31:0] sram_awaddr;
wire sram_awvalid;
wire sram_awready;
wire [31:0] sram_wdata;
wire [7:0] sram_wstrb;
wire sram_wvalid;
wire sram_wready;
wire [1:0] sram_bresp;
wire sram_bvalid;
wire sram_bready;

wire [31:0] uart_awaddr;
wire uart_awvalid;
wire uart_awready;
wire [31:0] uart_wdata;
wire [7:0] uart_wstrb;
wire uart_wvalid;
wire uart_wready;
wire [1:0] uart_bresp;
wire uart_bvalid;
wire uart_bready;

wire [31:0] clint_araddr;
wire clint_arvalid;
wire clint_arready;
wire [31:0] clint_rdata;
wire clint_rvalid;
wire clint_rready;
wire [1:0] clint_rresp;

ysyx_24110006_PC mpc(
  .i_clock(clock),
  .i_reset(reset),
  .i_jump(jump||branch||trap),
  .i_upc(upc),
  .o_pc(pc),
  .i_valid(lsu_valid),
  .o_valid(pc_valid)
);

ysyx_24110006_IFU mifu(
  .i_clock(clock),
  .i_reset(reset),
  .i_pc(pc),
  .o_inst(inst),
  .i_valid(pc_valid),
  .o_valid(ifu_valid),
  .o_axi_araddr(ifu_araddr),
  .o_axi_arvalid(ifu_arvalid),
  .i_axi_arready(ifu_arready),
  .i_axi_rdata(ifu_rdata),
  .i_axi_rvalid(ifu_rvalid),
  .o_axi_rready(ifu_rready),
  .i_axi_rresp(ifu_rresp)
);



ysyx_24110006_IDU midu(
  .i_clock(clock),
  .i_reset(reset),
  .i_inst(inst),
  .o_op(op),
  .o_func(func),
  .o_reg_rs1(reg_rs1),
  .o_reg_rs2(reg_rs2),
  .o_reg_rd(reg_rd),
  .o_imm(imm),
  .o_csr_t(csr_t),
  .i_valid(ifu_valid),
  .o_valid(idu_valid)
);

ysyx_24110006_RegisterFile mreg(
  .i_clock(clock),
  .i_waddr(reg_rd),
  .i_wdata(reg_wdata),
  .i_raddr1(reg_rs1),
  .i_raddr2(reg_rs2),
  .i_wen(reg_wen),
  .o_rdata1(reg_src1),
  .o_rdata2(reg_src2),
  .i_valid(lsu_valid)
);

ysyx_24110006_CSR mcsr(
  .i_clock(clock),
  .i_reset(reset),
  .i_wen(csr_wen),
  .i_csr_t(csr_t),
  .i_csr(csr),
  .i_pc(pc),
  .i_mcause(csr_mcause),
  .i_wdata(csr_wdata),
  .o_rdata(csr_src),
  .o_upc(csr_upc),
  .i_valid(exu_valid)
);

ysyx_24110006_EXU mexu(
  .i_clock(clock),
  .i_reset(reset),
  .i_op(op),
  .i_func(func),
  .i_reg_src1(reg_src1),
  .i_reg_src2(reg_src2),
  .i_csr_src(csr_src),
  .i_imm(imm),
  .i_pc(pc),
  .i_csr_upc(csr_upc),
  .o_result(exu_result),
  .o_upc(upc),
  .o_reg_wen(reg_wen),
  .o_csr_wen(csr_wen),
  .o_result_t(result_t),
  .o_jump(jump),
  .o_trap(trap),
  .o_branch(branch),
  .o_mem_ren(mem_ren),
  .o_mem_wen(mem_wen),
  .o_mem_wmask(mem_wmask),
  .o_mem_read_t(mem_read_t),
  .i_valid(idu_valid),
  .o_valid(exu_valid)
);


ysyx_24110006_LSU mlsu(
  .i_clock(clock),
  .i_reset(reset),
  .i_ren(mem_ren),
  .i_wen(mem_wen),
  .i_addr(mem_addr),
  .i_wdata(mem_wdata),
  .i_wmask(mem_wmask),
  .i_read_t(mem_read_t),
  .o_rdata(mem_rdata),
  .i_valid(exu_valid),
  .o_valid(lsu_valid),
  .o_axi_araddr(lsu_araddr),
  .o_axi_arvalid(lsu_arvalid),
  .i_axi_arready(lsu_arready),
  .i_axi_rdata(lsu_rdata),
  .i_axi_rvalid(lsu_rvalid),
  .o_axi_rready(lsu_rready),
  .i_axi_rresp(lsu_rresp),
  .o_axi_awaddr(lsu_awaddr),
  .o_axi_awvalid(lsu_awvalid),
  .i_axi_awready(lsu_awready),
  .o_axi_wdata(lsu_wdata),
  .o_axi_wstrb(lsu_wstrb),
  .o_axi_wvalid(lsu_wvalid),
  .i_axi_wready(lsu_wready),
  .i_axi_bresp(lsu_bresp),
  .i_axi_bvalid(lsu_bvalid),
  .o_axi_bready(lsu_bready)
);

ysyx_24110006_ARBITER marbiter(
  .i_clock(clock),
  .i_reset(reset),
  .i_axi_araddr0(ifu_araddr),
  .i_axi_arvalid0(ifu_arvalid),
  .o_axi_arready0(ifu_arready),
  .o_axi_rdata0(ifu_rdata),
  .o_axi_rvalid0(ifu_rvalid),
  .o_axi_rresp0(ifu_rresp),
  .i_axi_rready0(ifu_rready),
  .i_axi_araddr1(lsu_araddr),
  .i_axi_arvalid1(lsu_arvalid),
  .o_axi_arready1(lsu_arready),
  .o_axi_rdata1(lsu_rdata),
  .o_axi_rvalid1(lsu_rvalid),
  .o_axi_rresp1(lsu_rresp),
  .i_axi_rready1(lsu_rready),
  .i_axi_awaddr1(lsu_awaddr),
  .i_axi_awvalid1(lsu_awvalid),
  .o_axi_awready1(lsu_awready),
  .i_axi_wdata1(lsu_wdata),
  .i_axi_wstrb1(lsu_wstrb),
  .i_axi_wvalid1(lsu_wvalid),
  .o_axi_wready1(lsu_wready),
  .o_axi_bresp1(lsu_bresp),
  .o_axi_bvalid1(lsu_bvalid),
  .i_axi_bready1(lsu_bready),
  .o_axi_araddr(xbar_araddr),
  .o_axi_arvalid(xbar_arvalid),
  .i_axi_arready(xbar_arready),
  .i_axi_rdata(xbar_rdata),
  .i_axi_rvalid(xbar_rvalid),
  .o_axi_rready(xbar_rready),
  .i_axi_rresp(xbar_rresp),
  .o_axi_awaddr(xbar_awaddr),
  .o_axi_awvalid(xbar_awvalid),
  .i_axi_awready(xbar_awready),
  .o_axi_wdata(xbar_wdata),
  .o_axi_wstrb(xbar_wstrb),
  .o_axi_wvalid(xbar_wvalid),
  .i_axi_wready(xbar_wready),
  .i_axi_bresp(xbar_bresp),
  .i_axi_bvalid(xbar_bvalid),
  .o_axi_bready(xbar_bready)
);

ysyx_24110006_XBAR mxbar(
  .i_axi_araddr(xbar_araddr),
  .i_axi_arvalid(xbar_arvalid),
  .o_axi_arready(xbar_arready),
  .o_axi_rdata(xbar_rdata),
  .o_axi_rvalid(xbar_rvalid),
  .o_axi_rresp(xbar_rresp),
  .i_axi_rready(xbar_rready),
  .i_axi_awaddr(xbar_awaddr),
  .i_axi_awvalid(xbar_awvalid),
  .o_axi_awready(xbar_awready),
  .i_axi_wdata(xbar_wdata),
  .i_axi_wstrb(xbar_wstrb),
  .i_axi_wvalid(xbar_wvalid),
  .o_axi_wready(xbar_wready),
  .o_axi_bresp(xbar_bresp),
  .o_axi_bvalid(xbar_bvalid),
  .i_axi_bready(xbar_bready),
  .o_axi_araddr0(sram_araddr),
  .o_axi_arvalid0(sram_arvalid),
  .i_axi_arready0(sram_arready),
  .i_axi_rdata0(sram_rdata),
  .i_axi_rvalid0(sram_rvalid),
  .o_axi_rready0(sram_rready),
  .i_axi_rresp0(sram_rresp),
  .o_axi_awaddr0(sram_awaddr),
  .o_axi_awvalid0(sram_awvalid),
  .i_axi_awready0(sram_awready),
  .o_axi_wdata0(sram_wdata),
  .o_axi_wstrb0(sram_wstrb),
  .o_axi_wvalid0(sram_wvalid),
  .i_axi_wready0(sram_wready),
  .i_axi_bresp0(sram_bresp),
  .i_axi_bvalid0(sram_bvalid),
  .o_axi_bready0(sram_bready),
  .o_axi_awaddr1(uart_awaddr),
  .o_axi_awvalid1(uart_awvalid),
  .i_axi_awready1(uart_awready),
  .o_axi_wdata1(uart_wdata),
  .o_axi_wstrb1(uart_wstrb),
  .o_axi_wvalid1(uart_wvalid),
  .i_axi_wready1(uart_wready),
  .i_axi_bresp1(uart_bresp),
  .i_axi_bvalid1(uart_bvalid),
  .o_axi_bready1(uart_bready),
  .o_axi_araddr2(clint_araddr),
  .o_axi_arvalid2(clint_arvalid),
  .i_axi_arready2(clint_arready),
  .i_axi_rdata2(clint_rdata),
  .i_axi_rvalid2(clint_rvalid),
  .o_axi_rready2(clint_rready),
  .i_axi_rresp2(clint_rresp)
);

ysyx_24110006_SRAM msram(
  .i_clock(clock),
  .i_reset(reset),
  .i_axi_araddr(sram_araddr),
  .i_axi_arvalid(sram_arvalid),
  .o_axi_arready(sram_arready),
  .o_axi_rdata(sram_rdata),
  .o_axi_rvalid(sram_rvalid),
  .o_axi_rresp(sram_rresp),
  .i_axi_rready(sram_rready),
  .i_axi_awaddr(sram_awaddr),
  .i_axi_awvalid(sram_awvalid),
  .o_axi_awready(sram_awready),
  .i_axi_wdata(sram_wdata),
  .i_axi_wstrb(sram_wstrb),
  .i_axi_wvalid(sram_wvalid),
  .o_axi_wready(sram_wready),
  .o_axi_bresp(sram_bresp),
  .o_axi_bvalid(sram_bvalid),
  .i_axi_bready(sram_bready)
);

ysyx_24110006_UART muart(
  .i_clock(clock),
  .i_reset(reset),
  .i_axi_awaddr(uart_awaddr),
  .i_axi_awvalid(uart_awvalid),
  .o_axi_awready(uart_awready),
  .i_axi_wdata(uart_wdata),
  .i_axi_wstrb(uart_wstrb),
  .i_axi_wvalid(uart_wvalid),
  .o_axi_wready(uart_wready),
  .o_axi_bresp(uart_bresp),
  .o_axi_bvalid(uart_bvalid),
  .i_axi_bready(uart_bready)
);

ysyx_24110006_CLINT mclint(
  .i_clock(clock),
  .i_reset(reset),
  .i_axi_araddr(clint_araddr),
  .i_axi_arvalid(clint_arvalid),
  .o_axi_arready(clint_arready),
  .o_axi_rdata(clint_rdata),
  .o_axi_rvalid(clint_rvalid),
  .o_axi_rresp(clint_rresp),
  .i_axi_rready(clint_rready)
);

endmodule
