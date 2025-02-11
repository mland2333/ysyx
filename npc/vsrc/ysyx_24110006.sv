`ifndef CONFIG_YOSYS
import "DPI-C" function void quit();
import "DPI-C" function void difftest();
import "DPI-C" function void diff_skip();
import "DPI-C" function void fetch_inst();
`endif
`include "alu_config.sv"
`include "common_config.sv"
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
wire flush;
wire stall;
wire exception;
wire branch;
wire csr_flush;
wire [31:0] upc;
wire jal_btb_update;
wire branch_btb_update;
wire btb_update;
wire predict_err;
wire [31:0] btb_pc;
assign exception = lsu_valid & lsu_exception;
assign branch = lsu_valid & lsu_branch;
assign csr_flush = lsu_valid & lsu_csr_t[0];
assign flush = exu_flush | exception | branch | csr_flush;
`ifdef CONFIG_BTB
  assign upc = exception ? csr_upc : (branch | branch_btb_update) ? lsu_upc : exu_upc;
`else
  assign upc = exception ? csr_upc : branch ? lsu_upc : exu_upc;
`endif
assign jal_btb_update = exu_btb_update;
assign branch_btb_update = lsu_btb_update & lsu_valid & branch;
assign btb_update = jal_btb_update | branch_btb_update;
assign predict_err = lsu_predict_err & lsu_valid;
assign btb_pc = (branch_btb_update | predict_err) ? lsu_pc : (jal_btb_update | fencei) ? exu_pc : 0;
wire [`BRANCH_MID] branch_mid;
wire lsu_branch;
wire arbiter_ifu_read;
wire ifu_predict, idu_predict, exu_predict, lsu_predict;
wire exu_btb_update, lsu_btb_update;
wire lsu_predict_err;
 
wire idu_mret;
wire exu_flush;
wire exu_cmp;
wire exu_zero;
wire exu_jump;
wire exu_trap;
wire exu_result_t;
wire [3:0] exu_alu_t;

wire [31:0] exu_result, lsu_result;
wire idu_reg_wen, exu_reg_wen, lsu_reg_wen;

wire [31:0] pc, ifu_pc, idu_pc, exu_pc, lsu_pc;
wire [31:0] exu_upc, lsu_upc, csr_upc;

wire [31:0] ifu_inst;
wire [6:0] idu_op, exu_op, lsu_op;
wire [2:0] idu_func;
wire [4:0] idu_rs1, idu_rs2, idu_rd, exu_rd, lsu_rd;
wire [31:0] ifu_imm, idu_imm;
wire fencei;

wire [31:0] reg_src1, reg_src2;
wire [31:0] reg_wdata;
wire [31:0] csr_src;
wire [31:0] forward_src1, forward_src2;
wire [31:0] src1, src2;
assign src1 = forward_src1;
assign src2 = forward_src2;


wire [11:0] idu_csr, exu_csr, lsu_csr;
wire [1:0] idu_csr_t, exu_csr_t, lsu_csr_t;
wire [31:0] csr_wdata;
wire ifu_exception, idu_exception, exu_exception, lsu_exception;
wire [3:0] ifu_mcause, idu_mcause, exu_mcause, lsu_mcause;
wire [31:0] alu_a, alu_b;
wire [`ALU_TYPE-1:0] alu_t;
wire alu_sign, alu_sub;

wire exu_mem_ren, exu_mem_wen;
wire [3:0] exu_mem_wmask;
wire [2:0] exu_mem_read_t;
wire [31:0] exu_mem_addr;
wire [31:0] mem_wdata;
wire [31:0] mem_rdata;
wire lsu_jump;
wire mret = lsu_csr_t[1];
wire jump = lsu_jump | lsu_exception | mret;
assign csr_wdata = lsu_result;
wire lsu_wen, lsu_ren;
wire pc_valid, ifu_valid, idu_valid, exu_valid, lsu_valid;
wire ifu_ready, idu_ready, exu_ready, lsu_ready;
reg [31:0] sim_pc;
wire sim_branch;
`ifdef CONFIG_SIM
  wire is_diff_skip;
  wire [31:0] lsu_addr;
  `ifndef CONFIG_YSYXSOC
    assign is_diff_skip = clint_rvalid || uart_bvalid || lsu_valid && (exu_mem_ren || exu_mem_wen) && exu_result >= 32'ha0000000;
  `else
    assign is_diff_skip = clint_axi.rvalid || (lsu_wen||lsu_ren)&&(lsu_addr >= 32'h10000000 && lsu_addr < 32'h10001000 || lsu_addr >= 32'h02000000 && lsu_addr < 32'h03000000);
  `endif


  always@(posedge clock)begin
    if(reset) sim_pc <= 0;
    else begin
      if(lsu_valid) sim_pc <= (lsu_jump | sim_branch) ? lsu_upc : lsu_exception ? upc : lsu_pc + 4;
    end
  end

  always@(posedge clock)begin
    if(lsu_valid) begin
      if(is_diff_skip) diff_skip();
      difftest();
    end
  end
  always@(posedge clock)begin
    if(ifu_valid) fetch_inst();
  end

  always@ *
    if(ifu_inst == 32'h100073)
      quit();
  reg[31:0] npc_upc;
  always@(posedge clock)
    npc_upc <= exu_upc;

wire reg_valid;
`endif

AXIFULL_READ ifu_axi();
AXIFULL lsu_axi();
AXIFULL xbar_axi();
AXIFULL mem_axi();
`ifdef CONFIG_YSYXSOC
assign io_master_awvalid = mem_axi.awvalid;
assign io_master_awaddr  = mem_axi.awaddr;
assign io_master_awid    = mem_axi.awid;
assign io_master_awlen   = mem_axi.awlen;
assign io_master_awsize  = mem_axi.awsize;
assign io_master_awburst = mem_axi.awburst;
assign mem_axi.awready = io_master_awready;
assign io_master_wvalid  = mem_axi.wvalid;
assign io_master_wdata   = mem_axi.wdata;
assign io_master_wstrb   = mem_axi.wstrb;
assign io_master_wlast   = mem_axi.wlast;
assign mem_axi.wready  = io_master_wready;
assign io_master_bready  = mem_axi.bready;
assign mem_axi.bvalid  = io_master_bvalid;
assign mem_axi.bresp   = io_master_bresp;
assign mem_axi.bid     = io_master_bid;
assign io_master_arvalid = mem_axi.arvalid;
assign io_master_araddr  = mem_axi.araddr;
assign io_master_arid    = mem_axi.arid;
assign io_master_arlen   = mem_axi.arlen;
assign io_master_arsize  = mem_axi.arsize;
assign io_master_arburst = mem_axi.arburst;
assign mem_axi.arready = io_master_arready;
assign io_master_rready  = mem_axi.rready;
assign mem_axi.rvalid  = io_master_rvalid;
assign mem_axi.rresp   = io_master_rresp;
assign mem_axi.rdata   = io_master_rdata;
assign mem_axi.rlast   = io_master_rlast;
assign mem_axi.rid     = io_master_rid;
`else
AXIFULL_WRITE uart_axi();
`endif
AXIFULL_READ clint_axi();

ysyx_24110006_IFU mifu(
  .i_clock(clock),
  .i_reset(reset),
  .i_upc(upc),
  .i_busy(arbiter_ifu_read),
  .o_inst(ifu_inst),
  .i_fencei(fencei),
  .o_pc(ifu_pc),
  .o_exception(ifu_exception),
  .o_mcause(ifu_mcause),
`ifdef CONFIG_BTB
  .i_pc(btb_pc),
  .o_predict(ifu_predict),
  .i_predict_err(predict_err),
  .i_btb_update(btb_update),
`endif
  .i_valid(pc_valid),
  .o_valid(ifu_valid),
  .i_ready((idu_ready||exu_ready||lsu_ready)&&!stall),
  .o_ready(ifu_ready),
  .i_flush(flush),
  .out(ifu_axi.master)
);

ysyx_24110006_IMM mimm(
  .i_inst(ifu_inst),
  .o_imm(ifu_imm)
);

ysyx_24110006_IDU midu(
  .i_clock(clock),
  .i_reset(reset),
  .i_inst(ifu_inst),
  .i_imm(ifu_imm),
  .i_pc(ifu_pc),
  .o_op(idu_op),
  .o_func(idu_func),
  .o_reg_rs1(idu_rs1),
  .o_reg_rs2(idu_rs2),
  .o_reg_rd(idu_rd),
  .o_reg_wen(idu_reg_wen),
  .o_imm(idu_imm),
  .o_pc(idu_pc),
  .o_csr_t(idu_csr_t),
  .i_exception(ifu_exception),
  .o_exception(idu_exception),
  .i_mcause(ifu_mcause),
  .o_mcause(idu_mcause),
  .o_csr(idu_csr),
  .o_mret(idu_mret),
`ifdef CONFIG_BTB
  .i_predict(ifu_predict),
  .o_predict(idu_predict),
`endif
  .i_valid(ifu_valid),
  .o_valid(idu_valid),
  .i_ready(exu_ready||lsu_ready),
  .o_ready(idu_ready),
  .i_flush(flush),
  .i_stall(stall),
  .i_wen(exu_mem_wen),
  .i_ren(exu_mem_ren)
);

ysyx_24110006_RegisterFile mreg(
  .i_clock(clock),
  .i_reset(reset),
  .i_waddr(lsu_rd),
  .i_wdata(lsu_result),
  .i_raddr1(idu_rs1),
  .i_raddr2(idu_rs2),
  .i_wen(lsu_reg_wen),
  .o_rdata1(reg_src1),
  .o_rdata2(reg_src2),
  .i_valid(lsu_valid),
  .o_valid(reg_valid)
);

ysyx_24110006_CSR mcsr(
  .i_clock(clock),
  .i_reset(reset),
  .i_csr_t(lsu_csr_t),
  .i_csr_r(idu_csr),
  .i_mret(idu_mret),
  .i_csr_w(lsu_csr),
  .i_pc(lsu_pc),
  .i_exception(exception),
  .i_mcause(lsu_mcause),
  .i_wdata(lsu_result),
  .o_rdata(csr_src),
  .o_upc(csr_upc),
  .i_valid(lsu_valid)
);

ysyx_24110006_FORWARD_STALL mforward_stall(
  .i_valid(idu_valid),
  .i_op(idu_op),
  .i_rs1(idu_rs1),
  .i_rs2(idu_rs2),
  .i_reg_src1(reg_src1),
  .i_reg_src2(reg_src2),
  .i_lsu_data(lsu_result),
  .i_exu_data(exu_result),
  .i_exu_load(exu_mem_ren),
  .i_lsu_load(lsu_ren),
  .i_exu_valid(exu_valid),
  .i_lsu_valid(lsu_valid),
  .i_lsu_ready(lsu_ready),
  .i_exu_rd(exu_rd),
  .i_lsu_rd(lsu_rd),
  .i_exu_wen(exu_reg_wen),
  .i_lsu_wen(lsu_reg_wen),
  .o_src1(forward_src1),
  .o_src2(forward_src2),
  .o_stall(stall)
);

ysyx_24110006_ALUOP maluop(
  .i_src1(src1),
  .i_src2(src2),
  .i_imm(idu_imm),
  .i_csr_rdata(csr_src),
  .i_pc(idu_pc),
  .i_op(idu_op),
  .i_func(idu_func),
  .o_alu_a(alu_a),
  .o_alu_b(alu_b),
  .o_alu_sub(alu_sub),
  .o_alu_sign(alu_sign),
  .o_alu_t(alu_t)
);

ysyx_24110006_EXU mexu(
  .i_clock(clock),
  .i_reset(reset),
  .i_alu_a(alu_a),
  .i_alu_b(alu_b),
  .i_alu_sub(alu_sub),
  .i_alu_sign(alu_sign),
  .i_alu_t(alu_t),
  .i_op(idu_op),
  .i_func(idu_func),
  .i_reg_src1(src1),
  .i_reg_src2(src2),
  .i_reg_rd(idu_rd),
  .i_csr_t(idu_csr_t),
  .i_imm(idu_imm),
  .i_pc(idu_pc),
  .o_result(exu_result),
  .o_upc(exu_upc),
  .o_pc(exu_pc),
  .o_reg_wen(exu_reg_wen),
  .o_result_t(exu_result_t),
  .o_csr_t(exu_csr_t),
  .o_jump(exu_jump),
  .o_reg_rd(exu_rd),
  .o_mem_ren(exu_mem_ren),
  .o_mem_wen(exu_mem_wen),
  .o_mem_wmask(exu_mem_wmask),
  .o_mem_read_t(exu_mem_read_t),
  .o_mem_addr(exu_mem_addr),
  .o_mem_wdata(mem_wdata),
  .o_fencei(fencei),
  .o_op(exu_op),
  .o_branch_mid(branch_mid),
  .i_exception(idu_exception),
  .o_exception(exu_exception),
  .i_mcause(idu_mcause),
  .o_mcause(exu_mcause),
  .i_csr(idu_csr),
  .o_csr(exu_csr),
  .i_csr_upc(csr_upc),
`ifdef CONFIG_BTB
  .i_predict(idu_predict),
  .o_predict(exu_predict),
  .o_btb_update(exu_btb_update),
`endif
  .i_valid(idu_valid&&!stall),
  .o_valid(exu_valid),
  .i_ready(lsu_ready),
  .o_ready(exu_ready),
  .i_flush(flush),
  .o_flush(exu_flush)
);

ysyx_24110006_LSU mlsu(
  .i_clock(clock),
  .i_reset(reset),
  .i_ren(exu_mem_ren),
  .i_wen(exu_mem_wen),
  .i_wdata(mem_wdata),
  .i_wmask(exu_mem_wmask),
  .i_read_t(exu_mem_read_t),
  .i_result_t(exu_result_t),
  .i_reg_wen(exu_reg_wen),
  .i_result(exu_result),
  .i_reg_rd(exu_rd),
  .i_csr_t(exu_csr_t),

  .o_result(lsu_result),
  .o_reg_wen(lsu_reg_wen),
  .o_reg_rd(lsu_rd),
  .o_csr_t(lsu_csr_t),
  .i_exception(exu_exception),
  .o_exception(lsu_exception),
  .i_mcause(exu_mcause),
  .o_mcause(lsu_mcause),
  .i_jump(exu_jump),
  .o_jump(lsu_jump),
  .i_pc(exu_pc),
  .o_pc(lsu_pc),
  .i_csr(exu_csr),
  .o_csr(lsu_csr),
  .o_ren(lsu_ren),
  .i_upc(exu_upc),
  .o_upc(lsu_upc),
  .i_branch_mid(branch_mid),
  .o_branch(lsu_branch),
`ifdef CONFIG_BTB
  .i_predict(exu_predict),
  .o_predict(lsu_predict),
  .o_predict_err(lsu_predict_err),
  .o_btb_update(lsu_btb_update),
`endif
`ifdef CONFIG_SIM
  .i_op(exu_op),
  .o_op(lsu_op),
  .o_wen(lsu_wen),
  .o_addr(lsu_addr),
  .o_sim_branch(sim_branch),
`endif
  .i_valid(exu_valid),
  .o_valid(lsu_valid),
  .i_ready(1),
  .o_ready(lsu_ready),
  .i_flush(exception|branch),

  .out(lsu_axi.master)
);

ysyx_24110006_ARBITER marbiter(
  .i_clock(clock),
  .i_reset(reset),
  .i_flush(flush),
  .o_busy(arbiter_ifu_read),
  .ifu(ifu_axi.slave),
  .lsu(lsu_axi.slave),
  .out(xbar_axi.master)
);

ysyx_24110006_XBAR mxbar(
  .i_clock(clock),
  .i_reset(reset),
  .in(xbar_axi.slave),
  .mem(mem_axi.master),
`ifndef CONFIG_YSYXSOC
  .uart(uart_axi),
`endif
  .clint(clint_axi.master)
);

`ifndef CONFIG_YSYXSOC
ysyx_24110006_SRAM msram(
  .i_clock(clock),
  .i_reset(reset),
  .in(mem_axi.slave)
);

ysyx_24110006_UART muart(
  .i_clock(clock),
  .i_reset(reset),
  .in(uart_axi.slave)
);
`endif

ysyx_24110006_CLINT mclint(
  .i_clock(clock),
  .i_reset(reset),
  .in(clint_axi.slave)
);

endmodule
