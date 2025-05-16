/* import "DPI-C" function int pmem_read(input int raddr); */
/* import "DPI-C" function void pmem_write( */
/*   input int waddr, input int wdata, input byte wmask); */
/**/
`include "common_config.sv"
module ysyx_24110006_LSU (
    input i_clock,
    input i_reset,
    input i_ren,
    input i_wen,
    input [31:0] i_wdata,
    input [3:0] i_wmask,
    input [2:0] i_read_t,
    input [4:0] i_reg_rd,
    input i_reg_wen,
    input [31:0] i_addr,
    output o_reg_wen,
    output logic [31:0] o_result,
    output [4:0] o_reg_rd,
    output o_ren,
    input i_exception,
    output o_exception,
    input [3:0] i_mcause,
    output [3:0] o_mcause,
    input i_flush,
    input [31:0] i_pc,
    output [31:0] o_pc,
`ifdef CONFIG_SIM
    input [6:0] i_op,
    output [6:0] o_op,
    output o_wen,
    output [31:0] o_addr,
`endif
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    if_lsu_adapter.master o_lsu_rq
);

  reg ren;
  reg wen;
  reg [31:0] addr;
  reg [31:0] wdata;
  reg [3:0] wmask;
  reg [2:0] read_t;
  /* reg [3:0] alu_t; */
  reg [4:0] reg_rd;
  reg reg_wen;
  reg [1:0] csr_t;
  /* wire mem_valid = ren&&rvalid&&rready || wen&&bvalid&&bready; */
  wire mem_valid = o_lsu_rq.valid;
  wire update_reg;

  always @(posedge i_clock) begin
    if (i_reset) o_vr.valid <= 0;
    else if (mem_valid) begin
      o_vr.valid <= 1;
    end else if (o_vr.valid) begin
      o_vr.valid <= 0;
    end
  end
  always @(posedge i_clock) begin
    if (i_reset || i_flush) i_vr.ready <= 1;
    else if (i_vr.ready && i_vr.valid && !i_flush) i_vr.ready <= 0;
    else if (!i_vr.ready && mem_valid) i_vr.ready <= 1;
  end
  assign update_reg = !i_reset && i_vr.valid && i_vr.ready && !i_flush;
  reg exception;
  always @(posedge i_clock) begin
    if (update_reg) exception <= i_exception;
  end
  assign o_exception = exception | my_exception;
  reg [3:0] mcause;
  always @(posedge i_clock) begin
    if (update_reg) mcause <= i_mcause;
  end
  assign o_mcause = exception ? mcause : my_mcause;
  /* wire load_addr_misaligned = ren & (addr[1:0] != 2'b0) & (read_t == 3'b010) | (addr[0] != 0) & read_t[0]; */
  /* wire store_addr_misaligned = wen && (addr[1:0] != 2'b0) & (wmask == 4'b1111) | (addr[0] != 0) & (wmask == 4'b0011); */
  wire load_addr_misaligned = 0;
  wire store_addr_misaligned = 0;
  wire my_exception = load_addr_misaligned | store_addr_misaligned;
  wire [3:0] my_mcause = ({4{load_addr_misaligned}} & 4'd4) | ({4{store_addr_misaligned}} & 4'd6);

  always @(posedge i_clock) begin
    if (i_reset) rdata <= 0;
    else if (ren && o_lsu_rq.valid) rdata <= rdata0;
  end

  always @(posedge i_clock) begin
    if (update_reg) ren <= i_ren;
  end
  assign o_ren = ren;

  reg [31:0] pc;
  always @(posedge i_clock) begin
    if (update_reg) pc <= i_pc;
  end
  assign o_pc = pc;
`ifdef CONFIG_SIM

  reg [6:0] op;
  always @(posedge i_clock) begin
    if (update_reg) op <= i_op;
  end
  assign o_op = op;
  always @(posedge i_clock) begin
    if (update_reg) wen <= i_wen;
  end
  assign o_wen  = wen;
  assign o_addr = addr;
`endif

  always @(posedge i_clock) begin
    if (update_reg) begin
      ren <= i_ren;
      wen <= i_wen;
      addr <= i_addr;
      wdata <= i_wdata;
      wmask <= i_wmask;
      read_t <= i_read_t;
      reg_rd <= i_reg_rd;
      reg_wen <= i_reg_wen;
    end
  end

  assign o_reg_wen = reg_wen;
  assign o_reg_rd  = reg_rd;

  reg [31:0] rdata, rdata0;
  reg [31:0] wdata0;
  reg [ 3:0] wmask0;

  always_comb begin
    unique case (addr[1:0])
      2'b00: begin
        rdata0 = o_lsu_rq.rdata;
      end
      2'b01: begin
        rdata0 = {8'b0, o_lsu_rq.rdata[31:8]};
      end
      2'b10: begin
        rdata0 = {16'b0, o_lsu_rq.rdata[31:16]};
      end
      2'b11: begin
        rdata0 = {24'b0, o_lsu_rq.rdata[31:24]};
      end
    endcase
  end

  always_comb begin
    case (read_t)
      3'b000:  o_result = {{24{rdata[7]}}, rdata[7:0]};
      3'b001:  o_result = {{16{rdata[15]}}, rdata[15:0]};
      3'b010:  o_result = rdata;
      3'b100:  o_result = {24'b0, rdata[7:0]};
      3'b101:  o_result = {16'b0, rdata[15:0]};
      default: o_result = rdata;
    endcase
  end


  always_comb begin
    if (wen) begin
      unique case (addr[1:0])
        2'b00: begin
          wdata0 = wdata;
          wmask0 = {wmask};
        end
        2'b01: begin
          wdata0 = {wdata[23:0], wdata[31:24]};
          wmask0 = {wmask[2:0], 1'b0};
        end
        2'b10: begin
          wdata0 = {wdata[15:0], wdata[31:16]};
          wmask0 = {wmask[1:0], 2'b0};
        end
        2'b11: begin
          wdata0 = {wdata[7:0], wdata[31:8]};
          wmask0 = {wmask[0], 3'b0};
        end
      endcase
    end else begin
      wdata0 = 0;
      wmask0 = 0;
    end
  end

  logic rq;
  always @(posedge i_clock) begin
    if (i_reset) rq <= 0;
    else if (i_vr.valid && i_vr.ready && !i_flush) rq <= 1;
    else if (rq) rq <= 0;
  end
  assign o_lsu_rq.wen = wen;
  assign o_lsu_rq.ren = ren;
  assign o_lsu_rq.rq = rq;
  assign o_lsu_rq.read_t = read_t;
  assign o_lsu_rq.addr = addr;
  assign o_lsu_rq.wdata = wdata0;
  assign o_lsu_rq.wmask = wmask;


  /* assign o_axi.araddr = addr; */
  /* assign o_axi.arvalid = arvalid; */
  /* assign arready = o_axi.arready; */
  /* assign o_axi.arid = 0; */
  /* assign o_axi.arlen = 0; */
  /* assign o_axi.arsize = i_read_t[1] ? 3'b010 : i_read_t[0] ? 3'b001 : 3'b000; */
  /* assign o_axi.arburst = 0; */
  /**/
  /* assign rvalid = o_axi.rvalid; */
  /* assign rresp = o_axi.rresp; */
  /* assign o_axi.rready = rready; */
  /**/
  /* assign o_axi.awaddr = addr; */
  /* assign o_axi.awvalid = awvalid; */
  /* assign awready = o_axi.awready; */
  /* assign o_axi.awid = 0; */
  /* assign o_axi.awlen = 0; */
  /* assign o_axi.awsize = wmask == 4'b0011 ? 3'b001 : wmask == 4'b1111 ? 3'b010 : 3'b000; */
  /* assign o_axi.awburst = 0; */
  /**/
  /* assign o_axi.wdata = wdata0; */
  /* assign o_axi.wstrb = wmask0; */
  /* assign o_axi.wvalid = wvalid; */
  /* assign wready = o_axi.wready; */
  /* assign o_axi.wlast = 1; */
  /**/
  /* assign bresp = o_axi.bresp; */
  /* assign bvalid = o_axi.bvalid; */
  /* assign o_axi.bready = bready; */

  /* always@(posedge i_clock) begin */
  /*   if(i_reset) arvalid <= 0; */
  /*   else if(update_reg && !arvalid && i_ren) arvalid <= 1; */
  /*   else if(arvalid && arready) arvalid <= 0; */
  /* end */

  /* always@(posedge i_clock)begin */
  /*    rready <= 1; */
  /* end */

  /* always@(posedge i_clock) begin */
  /*   if(i_reset) awvalid <= 0; */
  /*   else if(update_reg && !awvalid && i_wen) awvalid <= 1; */
  /*   else if(awvalid && awready && wvalid && wready) awvalid <= 0; */
  /* end */

  /* always@(posedge i_clock) begin */
  /*   if(i_reset) wvalid <= 0; */
  /*   else if(update_reg && !wvalid && i_wen) wvalid <= 1; */
  /*   else if(awvalid && awready && wvalid && wready) wvalid <= 0; */
  /* end */

  /* always@(posedge i_clock)begin */
  /*   bready <= 1; */
  /* end */


endmodule
