/* import "DPI-C" function int pmem_read(input int raddr); */
/* import "DPI-C" function void pmem_write( */
/*   input int waddr, input int wdata, input byte wmask); */
/**/
`include "common_config.sv"
module ysyx_24110006_LSU (
    input i_clock,
    input i_reset,
    input pipe::exu2lsu_t from_exu,
    output pipe::wbu_t to_wbu,
    output pipe::csr_einfo_t csr_einfo,
    output o_ren,
    input i_flush,
`ifdef CONFIG_SIM
    input pipe::sim_t i_sim,
    output pipe::sim_t o_sim,
    output o_wen,
    output [31:0] o_addr,
`endif
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    if_lsu_adapter.master o_lsu_rq
);
  pipe::exu2lsu_t exu_data;
  always_ff @(posedge i_clock) begin
    if (update_reg) exu_data <= from_exu;
  end
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
  /* reg exception; */
  /* always @(posedge i_clock) begin */
  /*   if (update_reg) exception <= i_exception; */
  /* end */
  /* assign o_exception = exception | my_exception; */
  /* reg [3:0] mcause; */
  /* always @(posedge i_clock) begin */
  /*   if (update_reg) mcause <= i_mcause; */
  /* end */
  /* assign o_mcause = exception ? mcause : my_mcause; */
  /* wire load_addr_misaligned = ren & (addr[1:0] != 2'b0) & (read_t == 3'b010) | (addr[0] != 0) & read_t[0]; */
  /* wire store_addr_misaligned = wen && (addr[1:0] != 2'b0) & (wmask == 4'b1111) | (addr[0] != 0) & (wmask == 4'b0011); */
  /* wire load_addr_misaligned = 0; */
  /* wire store_addr_misaligned = 0; */
  /* wire my_exception = load_addr_misaligned | store_addr_misaligned; */
  /* wire [3:0] my_mcause = ({4{load_addr_misaligned}} & 4'd4) | ({4{store_addr_misaligned}} & 4'd6); */

  assign o_ren = exu_data.ren;

`ifdef CONFIG_SIM

  always @(posedge i_clock) begin
    if (update_reg) o_sim <= i_sim;
  end
  assign o_wen  = exu_data.wen;
  assign o_addr = exu_data.addr;
`endif

  always @(posedge i_clock) begin
    if (update_reg) begin
      exu_data <= from_exu;
    end
  end

  reg [31:0] rdata, rdata_aligned, result;
  reg [31:0] wdata_aligned;
  reg [ 3:0] wmask_aligned;

  always_comb begin
    unique case (exu_data.addr[1:0])
      2'b00: begin
        rdata_aligned = o_lsu_rq.rdata;
      end
      2'b01: begin
        rdata_aligned = {8'b0, o_lsu_rq.rdata[31:8]};
      end
      2'b10: begin
        rdata_aligned = {16'b0, o_lsu_rq.rdata[31:16]};
      end
      2'b11: begin
        rdata_aligned = {24'b0, o_lsu_rq.rdata[31:24]};
      end
    endcase
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) rdata <= 0;
    else if (exu_data.ren && o_lsu_rq.valid) rdata <= rdata_aligned;
  end

  always_comb begin
    case (exu_data.read_t)
      3'b000:  result = {{24{rdata[7]}}, rdata[7:0]};
      3'b001:  result = {{16{rdata[15]}}, rdata[15:0]};
      3'b010:  result = rdata;
      3'b100:  result = {24'b0, rdata[7:0]};
      3'b101:  result = {16'b0, rdata[15:0]};
      default: result = rdata;
    endcase
  end

  logic [3:0] wmask;
  logic [31:0] wdata;
  assign wmask = exu_data.wmask;
  assign wdata = exu_data.wdata;
  always_comb begin
    if (exu_data.wen) begin
      unique case (exu_data.addr[1:0])
        2'b00: begin
          wdata_aligned = wdata;
          wmask_aligned = {wmask};
        end
        2'b01: begin
          wdata_aligned = {wdata[23:0], wdata[31:24]};
          wmask_aligned = {wmask[2:0], 1'b0};
        end
        2'b10: begin
          wdata_aligned = {wdata[15:0], wdata[31:16]};
          wmask_aligned = {wmask[1:0], 2'b0};
        end
        2'b11: begin
          wdata_aligned = {wdata[7:0], wdata[31:8]};
          wmask_aligned = {wmask[0], 3'b0};
        end
      endcase
    end else begin
      wdata_aligned = 0;
      wmask_aligned = 0;
    end
  end

  logic rq;
  always @(posedge i_clock) begin
    if (i_reset) rq <= 0;
    else if (i_vr.valid && i_vr.ready && !i_flush) rq <= 1;
    else if (rq && o_lsu_rq.ack) rq <= 0;
  end
  assign o_lsu_rq.wen = exu_data.wen;
  assign o_lsu_rq.ren = exu_data.ren;
  assign o_lsu_rq.rq = rq;
  assign o_lsu_rq.read_t = exu_data.read_t;
  assign o_lsu_rq.addr = exu_data.addr;
  assign o_lsu_rq.wdata = wdata_aligned;
  assign o_lsu_rq.wmask = wmask_aligned;
  assign o_lsu_rq.ready = 1;

  assign to_wbu.result = result;
  assign to_wbu.reg_wen = exu_data.reg_wen;
  assign to_wbu.reg_rd = exu_data.reg_rd;
  assign to_wbu.pc = exu_data.pc;
`ifdef CONFIG_RENAME
  assign to_wbu.has_old_map = exu_data.has_old_map;
  assign to_wbu.old_index = exu_data.old_index;
  assign to_wbu.is_flush = 0;
  assign to_wbu.vrd = exu_data.vrd;
`endif

  assign csr_einfo.pc = exu_data.pc;
  assign csr_einfo.exception = exu_data.exception;
  assign csr_einfo.mcause = exu_data.mcause;
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
