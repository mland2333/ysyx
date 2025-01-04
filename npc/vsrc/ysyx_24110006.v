`ifndef CONFIG_YOSYS
import "DPI-C" function void quit();
import "DPI-C" function void difftest();
import "DPI-C" function void diff_skip();
import "DPI-C" function void fetch_inst();
`endif

module ysyx_24110006(
  input clock,
`ifdef CONFIG_YSYXSOC
  input         io_interrupt,
  input         io_master_awready,
  output        io_master_awvalid,
  output [31:0] io_master_awaddr,
  output [3:0]  io_master_awid,
  output [7:0]  io_master_awlen,
  output [2:0]  io_master_awsize,
  output [1:0]  io_master_awburst,
  input         io_master_wready,
  output        io_master_wvalid,
  output [31:0] io_master_wdata,
  output [3:0]  io_master_wstrb,
  output        io_master_wlast,
  output        io_master_bready,
  input         io_master_bvalid,
  input  [1:0]  io_master_bresp,
  input  [3:0]  io_master_bid,
  input         io_master_arready,
  output        io_master_arvalid,
  output [31:0] io_master_araddr,
  output [3:0]  io_master_arid,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,
  output        io_master_rready,
  input         io_master_rvalid,
  input  [1:0]  io_master_rresp,
  input  [31:0] io_master_rdata,
  input         io_master_rlast,
  input  [3:0]  io_master_rid,

  output        io_slave_awready,
  input         io_slave_awvalid,
  input  [31:0] io_slave_awaddr,
  input  [3:0]  io_slave_awid,
  input  [7:0]  io_slave_awlen,
  input  [2:0]  io_slave_awsize,
  input  [1:0]  io_slave_awburst,
  output        io_slave_wready,
  input         io_slave_wvalid,
  input  [31:0] io_slave_wdata,
  input  [3:0]  io_slave_wstrb,
  input         io_slave_wlast,
  input         io_slave_bready,
  output        io_slave_bvalid,
  output [1:0]  io_slave_bresp,
  output [3:0]  io_slave_bid,
  output        io_slave_arready,
  input         io_slave_arvalid,
  input  [31:0] io_slave_araddr,
  input  [3:0]  io_slave_arid,
  input  [7:0]  io_slave_arlen,
  input  [2:0]  io_slave_arsize,
  input  [1:0]  io_slave_arburst,
  input         io_slave_rready,
  output        io_slave_rvalid,
  output [1:0]  io_slave_rresp,
  output [31:0] io_slave_rdata,
  output        io_slave_rlast,
  output [3:0]  io_slave_rid,
`endif
  input reset
);

wire exu_cmp;
wire exu_zero;
wire exu_jump;
wire exu_trap;
wire exu_reg_wen;
wire exu_csr_wen;
wire exu_result_t;
wire [3:0] exu_alu_t;
wire [31:0] exu_upc;
wire [31:0] exu_result;

wire [31:0] result;
wire result_t;
wire jump;
wire reg_wen;
wire csr_wen;

wire[31:0] pc, upc;

wire[31:0] inst;
wire[6:0] op;
wire[2:0] func;
wire[4:0] reg_rs1, reg_rs2, reg_rd;
wire[31:0] imm;
wire [31:0] ifu_imm;

wire[31:0] reg_src1, reg_src2;
wire[31:0] reg_wdata;
wire[31:0] csr_src;


wire[31:0] csr_mcause = 32'd11;
wire[31:0] csr_upc;
wire[11:0] csr = imm[11:0];
wire[1:0] csr_t;
wire[31:0] csr_wdata;

wire [31:0] alu_a, alu_b;
wire [3:0] alu_t;
wire alu_sign, alu_sub, alu_sra;

wire mem_ren, mem_wen;
wire[3:0] mem_wmask;
wire[2:0] mem_read_t;
wire[31:0] mem_addr;
wire[31:0] mem_wdata = reg_src2;
wire[31:0] mem_rdata;

assign reg_wdata = result_t ? mem_rdata : result;
assign csr_wdata = result;

wire pc_valid, ifu_valid, idu_valid, exu_valid, lsu_valid;

reg[31:0] npc_upc;
always@(posedge clock)
  npc_upc <= upc;

wire is_diff_skip;
`ifndef CONFIG_YSYXSOC
  assign is_diff_skip = clint_rvalid || uart_bvalid || lsu_valid && result >= 32'ha0000000;
`else
  assign is_diff_skip = clint_rvalid || lsu_valid && result >= 32'h10000000 && result < 32'h10001000;
`endif

`ifndef CONFIG_YOSYS
always@(posedge clock)begin
  if(is_diff_skip) diff_skip();
end

always@(posedge clock)begin
  if(ifu_valid) difftest();
end

always@(posedge clock)begin
  if(ifu_valid) fetch_inst();
end

always@ *
  if(inst == 32'h100073)
    quit();
`endif

wire [31:0] ifu_araddr;
wire ifu_arvalid;
wire ifu_arready;
wire [3:0] ifu_arid;
wire [7:0] ifu_arlen;
wire [2:0] ifu_arsize;
wire [1:0] ifu_arburst;
wire [31:0] ifu_rdata;
wire ifu_rvalid;
wire ifu_rready;
wire [1:0] ifu_rresp;
wire [3:0] ifu_rid;
wire ifu_rlast;




wire [31:0] lsu_araddr;
wire lsu_arvalid;
wire lsu_arready;
wire [3:0] lsu_arid;
wire [7:0] lsu_arlen;
wire [2:0] lsu_arsize;
wire [1:0] lsu_arburst;
wire [31:0] lsu_rdata;
wire lsu_rvalid;
wire lsu_rready;
wire [1:0] lsu_rresp;
wire [3:0] lsu_rid;
wire lsu_rlast;
wire [31:0] lsu_awaddr;
wire lsu_awvalid;
wire lsu_awready;
wire [3:0] lsu_awid;
wire [7:0] lsu_awlen;
wire [2:0] lsu_awsize;
wire [1:0] lsu_awburst;
wire [31:0] lsu_wdata;
wire [3:0] lsu_wstrb;
wire lsu_wvalid;
wire lsu_wready;
wire lsu_wlast;
wire [1:0] lsu_bresp;
wire lsu_bvalid;
wire lsu_bready;
wire [3:0] lsu_bid;

wire [31:0] xbar_araddr;
wire xbar_arvalid;
wire xbar_arready;
wire [3:0] xbar_arid;
wire [7:0] xbar_arlen;
wire [2:0] xbar_arsize;
wire [1:0] xbar_arburst;
wire [31:0] xbar_rdata;
wire xbar_rvalid;
wire xbar_rready;
wire [1:0] xbar_rresp;
wire [3:0] xbar_rid;
wire xbar_rlast;
wire [31:0] xbar_awaddr;
wire xbar_awvalid;
wire xbar_awready;
wire [3:0] xbar_awid;
wire [7:0] xbar_awlen;
wire [2:0] xbar_awsize;
wire [1:0] xbar_awburst;
wire [31:0] xbar_wdata;
wire [3:0] xbar_wstrb;
wire xbar_wvalid;
wire xbar_wready;
wire xbar_wlast;
wire [1:0] xbar_bresp;
wire xbar_bvalid;
wire xbar_bready;
wire [3:0] xbar_bid;

`ifndef CONFIG_YSYXSOC
/* wire [31:0] sram_araddr; */
/* wire sram_arvalid; */
/* wire sram_arready; */
/* wire [31:0] sram_rdata; */
/* wire sram_rvalid; */
/* wire sram_rready; */
/* wire [1:0] sram_rresp; */
/* wire [31:0] sram_awaddr; */
/* wire sram_awvalid; */
/* wire sram_awready; */
/* wire [31:0] sram_wdata; */
/* wire [7:0] sram_wstrb; */
/* wire sram_wvalid; */
/* wire sram_wready; */
/* wire [1:0] sram_bresp; */
/* wire sram_bvalid; */
/* wire sram_bready; */
wire [31:0] sram_araddr;
wire sram_arvalid;
wire sram_arready;
wire [3:0] sram_arid;
wire [7:0] sram_arlen;
wire [2:0] sram_arsize;
wire [1:0] sram_arburst;
wire [31:0] sram_rdata;
wire sram_rvalid;
wire sram_rready;
wire [1:0] sram_rresp;
wire [3:0] sram_rid;
wire sram_rlast;
wire [31:0] sram_awaddr;
wire sram_awvalid;
wire sram_awready;
wire [3:0] sram_awid;
wire [7:0] sram_awlen;
wire [2:0] sram_awsize;
wire [1:0] sram_awburst;
wire [31:0] sram_wdata;
wire [3:0] sram_wstrb;
wire sram_wvalid;
wire sram_wready;
wire sram_wlast;
wire [1:0] sram_bresp;
wire sram_bvalid;
wire sram_bready;
wire [3:0] sram_bid;

wire [31:0] uart_awaddr;
wire uart_awvalid;
wire uart_awready;
wire [3:0] uart_awid;
wire [7:0] uart_awlen;
wire [2:0] uart_awsize;
wire [1:0] uart_awburst;
wire [31:0] uart_wdata;
wire [3:0] uart_wstrb;
wire uart_wvalid;
wire uart_wready;
wire uart_wlast;
wire [1:0] uart_bresp;
wire uart_bvalid;
wire uart_bready;
wire [3:0] uart_bid;

`endif

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
  .i_jump(jump),
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
  .o_axi_arid(ifu_arid),
  .o_axi_arlen(ifu_arlen),
  .o_axi_arsize(ifu_arsize),
  .o_axi_arburst(ifu_arburst),
  .i_axi_rdata(ifu_rdata),
  .i_axi_rvalid(ifu_rvalid),
  .o_axi_rready(ifu_rready),
  .i_axi_rresp(ifu_rresp),
  .i_axi_rlast(ifu_rlast),
  .i_axi_rid(ifu_rid)
);

ysyx_24110006_IMM mimm(
  .i_inst(inst),
  .o_imm(ifu_imm)
);

ysyx_24110006_IDU midu(
  .i_clock(clock),
  .i_reset(reset),
  .i_inst(inst),
  .i_imm(ifu_imm),
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
  .i_valid(lsu_valid)
);

ysyx_24110006_ALUOP maluop(
  .i_src1(reg_src1),
  .i_src2(reg_src2),
  .i_imm(imm),
  .i_csr_rdata(csr_src),
  .i_pc(pc),
  .i_op(op),
  .i_func(func),
  .o_alu_a(alu_a),
  .o_alu_b(alu_b),
  .o_alu_sub(alu_sub),
  .o_alu_sign(alu_sign),
  .o_alu_t(alu_t),
  .o_alu_sra(alu_sra)
);

ysyx_24110006_EXU mexu(
  .i_clock(clock),
  .i_reset(reset),
  .i_alu_a(alu_a),
  .i_alu_b(alu_b),
  .i_alu_sub(alu_sub),
  .i_alu_sign(alu_sign),
  .i_alu_t(alu_t),
  .i_alu_sra(alu_sra),
  .i_op(op),
  .i_func(func),
  .i_reg_src1(reg_src1),
  .i_csr_src(csr_src),
  .i_imm(imm),
  .i_pc(pc),
  .i_csr_upc(csr_upc),
  .o_result(exu_result),
  .o_upc(exu_upc),
  .o_reg_wen(exu_reg_wen),
  .o_csr_wen(exu_csr_wen),
  .o_result_t(exu_result_t),
  .o_alu_t(exu_alu_t),
  .o_cmp(exu_cmp),
  .o_zero(exu_zero),
  .o_jump(exu_jump),
  .o_trap(exu_trap),
  .o_mem_ren(mem_ren),
  .o_mem_wen(mem_wen),
  .o_mem_wmask(mem_wmask),
  .o_mem_read_t(mem_read_t),
  .o_mem_addr(mem_addr),
  .i_valid(idu_valid),
  .o_valid(exu_valid)
);

ysyx_24110006_EXU_CTRL mexu_ctrl(
  .i_clock(clock),
  .i_reset(reset),
  .i_alu_t(exu_alu_t),
  .i_cmp(exu_cmp),
  .i_zero(exu_zero),
  .i_result_t(exu_result_t),
  .i_reg_wen(exu_reg_wen),
  .i_csr_wen(exu_csr_wen),
  .i_jump(exu_jump),
  .i_trap(exu_trap),
  .i_result(exu_result),
  .i_upc(exu_upc),
  
  .o_upc(upc),
  .o_result_t(result_t),
  .o_reg_wen(reg_wen),
  .o_csr_wen(csr_wen),
  .o_jump(jump),
  .o_result(result),

  .i_valid(exu_valid)
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
  .o_axi_arid(lsu_arid),
  .o_axi_arlen(lsu_arlen),
  .o_axi_arsize(lsu_arsize),
  .o_axi_arburst(lsu_arburst),
  .i_axi_rdata(lsu_rdata),
  .i_axi_rvalid(lsu_rvalid),
  .o_axi_rready(lsu_rready),
  .i_axi_rresp(lsu_rresp),
  .o_axi_rlast(lsu_rlast),
  .o_axi_rid(lsu_rid),
  .o_axi_awaddr(lsu_awaddr),
  .o_axi_awvalid(lsu_awvalid),
  .i_axi_awready(lsu_awready),
  .o_axi_awid(lsu_awid),
  .o_axi_awlen(lsu_awlen),
  .o_axi_awsize(lsu_awsize),
  .o_axi_awburst(lsu_awburst),
  .o_axi_wdata(lsu_wdata),
  .o_axi_wstrb(lsu_wstrb),
  .o_axi_wvalid(lsu_wvalid),
  .i_axi_wready(lsu_wready),
  .o_axi_wlast(lsu_wlast),
  .i_axi_bresp(lsu_bresp),
  .i_axi_bvalid(lsu_bvalid),
  .o_axi_bready(lsu_bready),
  .i_axi_bid(lsu_bid)
);

ysyx_24110006_ARBITER marbiter(
  .i_clock(clock),
  .i_reset(reset),
  .i_axi_araddr0(ifu_araddr),
  .i_axi_arvalid0(ifu_arvalid),
  .o_axi_arready0(ifu_arready),
  .i_axi_arid0(ifu_arid),
  .i_axi_arlen0(ifu_arlen),
  .i_axi_arsize0(ifu_arsize),
  .i_axi_arburst0(ifu_arburst),
  .o_axi_rdata0(ifu_rdata),
  .o_axi_rvalid0(ifu_rvalid),
  .o_axi_rresp0(ifu_rresp),
  .i_axi_rready0(ifu_rready),
  .o_axi_rlast0(ifu_rlast),
  .o_axi_rid0(ifu_rid),
  .i_axi_araddr1(lsu_araddr),
  .i_axi_arvalid1(lsu_arvalid),
  .o_axi_arready1(lsu_arready),
  .i_axi_arid1(lsu_arid),
  .i_axi_arlen1(lsu_arlen),
  .i_axi_arsize1(lsu_arsize),
  .i_axi_arburst1(lsu_arburst),
  .o_axi_rdata1(lsu_rdata),
  .o_axi_rvalid1(lsu_rvalid),
  .o_axi_rresp1(lsu_rresp),
  .i_axi_rready1(lsu_rready),
  .o_axi_rlast1(lsu_rlast),
  .o_axi_rid1(lsu_rid),
  .i_axi_awaddr1(lsu_awaddr),
  .i_axi_awvalid1(lsu_awvalid),
  .o_axi_awready1(lsu_awready),
  .i_axi_awid1(lsu_awid),
  .i_axi_awlen1(lsu_awlen),
  .i_axi_awsize1(lsu_awsize),
  .i_axi_awburst1(lsu_awburst),
  .i_axi_wdata1(lsu_wdata),
  .i_axi_wstrb1(lsu_wstrb),
  .i_axi_wvalid1(lsu_wvalid),
  .o_axi_wready1(lsu_wready),
  .i_axi_wlast1(lsu_wlast),
  .o_axi_bresp1(lsu_bresp),
  .o_axi_bvalid1(lsu_bvalid),
  .i_axi_bready1(lsu_bready),
  .o_axi_bid1(lsu_bid),
  .o_axi_araddr(xbar_araddr),
  .o_axi_arvalid(xbar_arvalid),
  .i_axi_arready(xbar_arready),
  .o_axi_arid(xbar_arid),
  .o_axi_arlen(xbar_arlen),
  .o_axi_arsize(xbar_arsize),
  .o_axi_arburst(xbar_arburst),
  .i_axi_rdata(xbar_rdata),
  .i_axi_rvalid(xbar_rvalid),
  .o_axi_rready(xbar_rready),
  .i_axi_rresp(xbar_rresp),
  .i_axi_rlast(xbar_rlast),
  .i_axi_rid(xbar_rid),
  .o_axi_awaddr(xbar_awaddr),
  .o_axi_awvalid(xbar_awvalid),
  .i_axi_awready(xbar_awready),
  .o_axi_awid(xbar_awid),
  .o_axi_awlen(xbar_awlen),
  .o_axi_awsize(xbar_awsize),
  .o_axi_awburst(xbar_awburst),
  .o_axi_wdata(xbar_wdata),
  .o_axi_wstrb(xbar_wstrb),
  .o_axi_wvalid(xbar_wvalid),
  .i_axi_wready(xbar_wready),
  .o_axi_wlast(xbar_wlast),
  .i_axi_bresp(xbar_bresp),
  .i_axi_bvalid(xbar_bvalid),
  .o_axi_bready(xbar_bready),
  .i_axi_bid(xbar_bid)
);

ysyx_24110006_XBAR mxbar(
  .i_clock(clock),
  .i_reset(reset),
  .i_axi_araddr(xbar_araddr),
  .i_axi_arvalid(xbar_arvalid),
  .o_axi_arready(xbar_arready),
  .i_axi_arid(xbar_arid),
  .i_axi_arlen(xbar_arlen),
  .i_axi_arsize(xbar_arsize),
  .i_axi_arburst(xbar_arburst),
  .o_axi_rdata(xbar_rdata),
  .o_axi_rvalid(xbar_rvalid),
  .o_axi_rresp(xbar_rresp),
  .i_axi_rready(xbar_rready),
  .o_axi_rlast(xbar_rlast),
  .o_axi_rid(xbar_rid),
  .i_axi_awaddr(xbar_awaddr),
  .i_axi_awvalid(xbar_awvalid),
  .o_axi_awready(xbar_awready),
  .i_axi_awid(xbar_awid),
  .i_axi_awlen(xbar_awlen),
  .i_axi_awsize(xbar_awsize),
  .i_axi_awburst(xbar_awburst),
  .i_axi_wdata(xbar_wdata),
  .i_axi_wstrb(xbar_wstrb),
  .i_axi_wvalid(xbar_wvalid),
  .o_axi_wready(xbar_wready),
  .i_axi_wlast(xbar_wlast),
  .o_axi_bresp(xbar_bresp),
  .o_axi_bvalid(xbar_bvalid),
  .i_axi_bready(xbar_bready),
  .o_axi_bid(xbar_bid),
`ifdef CONFIG_YSYXSOC
  .o_axi_araddr0(io_master_araddr),
  .o_axi_arvalid0(io_master_arvalid),
  .i_axi_arready0(io_master_arready),
  .o_axi_arid0(io_master_arid),
  .o_axi_arlen0(io_master_arlen),
  .o_axi_arsize0(io_master_arsize),
  .o_axi_arburst0(io_master_arburst),
  .i_axi_rdata0(io_master_rdata),
  .i_axi_rvalid0(io_master_rvalid),
  .o_axi_rready0(io_master_rready),
  .i_axi_rresp0(io_master_rresp),
  .i_axi_rlast0(io_master_rlast),
  .i_axi_rid0(io_master_rid),
  .o_axi_awaddr0(io_master_awaddr),
  .o_axi_awvalid0(io_master_awvalid),
  .i_axi_awready0(io_master_awready),
  .o_axi_awid0(io_master_awid),
  .o_axi_awlen0(io_master_awlen),
  .o_axi_awsize0(io_master_awsize),
  .o_axi_awburst0(io_master_awburst),
  .o_axi_wdata0(io_master_wdata),
  .o_axi_wstrb0(io_master_wstrb),
  .o_axi_wvalid0(io_master_wvalid),
  .i_axi_wready0(io_master_wready),
  .o_axi_wlast0(io_master_wlast),
  .i_axi_bresp0(io_master_bresp),
  .i_axi_bvalid0(io_master_bvalid),
  .o_axi_bready0(io_master_bready),
  .i_axi_bid0(io_master_bid),
`endif
`ifndef CONFIG_YSYXSOC
  /* .o_axi_araddr0(sram_araddr), */
  /* .o_axi_arvalid0(sram_arvalid), */
  /* .i_axi_arready0(sram_arready), */
  /* .i_axi_rdata0(sram_rdata), */
  /* .i_axi_rvalid0(sram_rvalid), */
  /* .o_axi_rready0(sram_rready), */
  /* .i_axi_rresp0(sram_rresp), */
  /* .o_axi_awaddr0(sram_awaddr), */
  /* .o_axi_awvalid0(sram_awvalid), */
  /* .i_axi_awready0(sram_awready), */
  /* .o_axi_wdata0(sram_wdata), */
  /* .o_axi_wstrb0(sram_wstrb), */
  /* .o_axi_wvalid0(sram_wvalid), */
  /* .i_axi_wready0(sram_wready), */
  /* .i_axi_bresp0(sram_bresp), */
  /* .i_axi_bvalid0(sram_bvalid), */
  /* .o_axi_bready0(sram_bready), */
  .o_axi_araddr0(sram_araddr),
  .o_axi_arvalid0(sram_arvalid),
  .i_axi_arready0(sram_arready),
  .o_axi_arid0(sram_arid),
  .o_axi_arlen0(sram_arlen),
  .o_axi_arsize0(sram_arsize),
  .o_axi_arburst0(sram_arburst),
  .i_axi_rdata0(sram_rdata),
  .i_axi_rvalid0(sram_rvalid),
  .o_axi_rready0(sram_rready),
  .i_axi_rresp0(sram_rresp),
  .i_axi_rlast0(sram_rlast),
  .i_axi_rid0(sram_rid),
  .o_axi_awaddr0(sram_awaddr),
  .o_axi_awvalid0(sram_awvalid),
  .i_axi_awready0(sram_awready),
  .o_axi_awid0(sram_awid),
  .o_axi_awlen0(sram_awlen),
  .o_axi_awsize0(sram_awsize),
  .o_axi_awburst0(sram_awburst),
  .o_axi_wdata0(sram_wdata),
  .o_axi_wstrb0(sram_wstrb),
  .o_axi_wvalid0(sram_wvalid),
  .i_axi_wready0(sram_wready),
  .o_axi_wlast0(sram_wlast),
  .i_axi_bresp0(sram_bresp),
  .i_axi_bvalid0(sram_bvalid),
  .o_axi_bready0(sram_bready),
  .i_axi_bid0(sram_bid),

  .o_axi_awaddr1(uart_awaddr),
  .o_axi_awvalid1(uart_awvalid),
  .i_axi_awready1(uart_awready),
  .o_axi_awid1(uart_awid),
  .o_axi_awlen1(uart_awlen),
  .o_axi_awsize1(uart_awsize),
  .o_axi_awburst1(uart_awburst),
  .o_axi_wdata1(uart_wdata),
  .o_axi_wstrb1(uart_wstrb),
  .o_axi_wvalid1(uart_wvalid),
  .i_axi_wready1(uart_wready),
  .o_axi_wlast1(uart_wlast),
  .i_axi_bresp1(uart_bresp),
  .i_axi_bvalid1(uart_bvalid),
  .o_axi_bready1(uart_bready),
  .i_axi_bid1(uart_bid),
`endif
  .o_axi_araddr2(clint_araddr),
  .o_axi_arvalid2(clint_arvalid),
  .i_axi_arready2(clint_arready),
  .i_axi_rdata2(clint_rdata),
  .i_axi_rvalid2(clint_rvalid),
  .o_axi_rready2(clint_rready),
  .i_axi_rresp2(clint_rresp)
);

`ifndef CONFIG_YSYXSOC
ysyx_24110006_SRAM msram(
  .i_clock(clock),
  .i_reset(reset),
  /* .i_axi_araddr(sram_araddr), */
  /* .i_axi_arvalid(sram_arvalid), */
  /* .o_axi_arready(sram_arready), */
  /* .o_axi_rdata(sram_rdata), */
  /* .o_axi_rvalid(sram_rvalid), */
  /* .o_axi_rresp(sram_rresp), */
  /* .i_axi_rready(sram_rready), */
  /* .i_axi_awaddr(sram_awaddr), */
  /* .i_axi_awvalid(sram_awvalid), */
  /* .o_axi_awready(sram_awready), */
  /* .i_axi_wdata(sram_wdata), */
  /* .i_axi_wstrb(sram_wstrb), */
  /* .i_axi_wvalid(sram_wvalid), */
  /* .o_axi_wready(sram_wready), */
  /* .o_axi_bresp(sram_bresp), */
  /* .o_axi_bvalid(sram_bvalid), */
  /* .i_axi_bready(sram_bready) */
  .i_axi_araddr(sram_araddr),
  .i_axi_arvalid(sram_arvalid),
  .o_axi_arready(sram_arready),
  .i_axi_arid(sram_arid),
  .i_axi_arlen(sram_arlen),
  .i_axi_arsize(sram_arsize),
  .i_axi_arburst(sram_arburst),
  .o_axi_rdata(sram_rdata),
  .o_axi_rvalid(sram_rvalid),
  .o_axi_rresp(sram_rresp),
  .i_axi_rready(sram_rready),
  .o_axi_rlast(sram_rlast),
  .o_axi_rid(sram_rid),
  .i_axi_awaddr(sram_awaddr),
  .i_axi_awvalid(sram_awvalid),
  .o_axi_awready(sram_awready),
  .i_axi_awid(sram_awid),
  .i_axi_awlen(sram_awlen),
  .i_axi_awsize(sram_awsize),
  .i_axi_awburst(sram_awburst),
  .i_axi_wdata(sram_wdata),
  .i_axi_wstrb(sram_wstrb),
  .i_axi_wvalid(sram_wvalid),
  .o_axi_wready(sram_wready),
  .i_axi_wlast(sram_wlast),
  .o_axi_bresp(sram_bresp),
  .o_axi_bvalid(sram_bvalid),
  .i_axi_bready(sram_bready),
  .o_axi_bid(sram_bid)
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
`endif

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
