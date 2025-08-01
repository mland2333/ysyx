/* import "DPI-C" function int pmem_read(input int raddr); */
/* import "DPI-C" function void pmem_write( */
/*   input int waddr, input int wdata, input byte wmask); */
/**/
`include "common_config.sv"
module ysyx_24110006_LSU (
    input i_clock,
    input i_reset,
    input ooo::lsu_info_t issue_inst,
    output rob::commit_info_t commit,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_lsu_adapter.master o_lsu_rq
);
  logic wen, ren;
  ooo::lsu_info_t lsu_info;
  always_ff @(posedge i_clock) begin
    if (update_reg) lsu_info <= issue_inst;
  end
  assign wen = lsu_info.wen;
  assign ren = !lsu_info.wen;
  wire  mem_valid = o_lsu_rq.valid;
  wire  update_reg;
  logic o_valid;
  always @(posedge i_clock) begin
    if (i_reset) o_valid <= 0;
    else if (mem_valid) begin
      o_valid <= 1;
    end else if (o_valid) begin
      o_valid <= 0;
    end
  end
  always @(posedge i_clock) begin
    if (i_reset || i_flush) i_vr.ready <= 1;
    else if (i_vr.ready && i_vr.valid && !i_flush) i_vr.ready <= 0;
    else if (!i_vr.ready && mem_valid) i_vr.ready <= 1;
  end
  assign update_reg = !i_reset && i_vr.valid && i_vr.ready && !i_flush;

  reg [31:0] rdata, rdata_aligned, result;
  reg [31:0] wdata_aligned;
  reg [ 3:0] wmask_aligned;

  always_comb begin
    unique case (lsu_info.addr[1:0])
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
    else if (ren && o_lsu_rq.valid) rdata <= rdata_aligned;
  end

  always_comb begin
    case (lsu_info.read_t)
      3'b000:  result = {{24{rdata[7]}}, rdata[7:0]};
      3'b001:  result = {{16{rdata[15]}}, rdata[15:0]};
      3'b010:  result = rdata;
      3'b100:  result = {24'b0, rdata[7:0]};
      3'b101:  result = {16'b0, rdata[15:0]};
      default: result = rdata;
    endcase
  end

  logic [ 3:0] wmask;
  logic [31:0] wdata;
  assign wmask = lsu_info.wmask;
  assign wdata = lsu_info.wdata;
  always_comb begin
    if (wen) begin
      unique case (lsu_info.addr[1:0])
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
  assign o_lsu_rq.wen = wen;
  assign o_lsu_rq.ren = ren;
  assign o_lsu_rq.rq = rq;
  assign o_lsu_rq.read_t = lsu_info.read_t;
  assign o_lsu_rq.addr = lsu_info.addr;
  assign o_lsu_rq.wdata = wdata_aligned;
  assign o_lsu_rq.wmask = wmask_aligned;
  assign o_lsu_rq.ready = 1;
  rob::result_t wb_result;
  assign wb_result.result = result;
  assign wb_result.flush = 0;
  assign wb_result.upc = 0;
  assign commit.result = wb_result;
  assign commit.valid = o_valid;
  assign commit.index = lsu_info.rob_index;
`ifdef CONFIG_SIM
  function logic in_mem(input int addr);
`ifdef CONFIG_YSYXSOC
    return addr >= 32'h0f000000 && addr < 32'h0fffffff || addr >= 32'h30000000 && addr < 32'h3fffffff || addr >= 32'ha0000000 && addr < 32'hbfffffff;
`else
    return addr >= 32'h80000000 && addr < 32'h90000000;
`endif
  endfunction
  assign wb_result.sim.difftest_skip = !in_mem(lsu_info.addr);
`endif
endmodule
