module ysyx_24110006_LOAD_UNIT (
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_rq_load.out o_rq,
    input lsu::rq_load_t i_rq,
    output rob::commit_info_t commit,
    output rename::commit_t rename_commit,
    output rf::winfo_t winfo,
    output bypass::wakeup_t lsu_wakeup,
    if_load_check.out check
);
  lsu::rq_load_t rq;
  logic in_flush;
  logic r_valid, r_ready;
  assign r_valid = i_vr.valid && !check.stall;
  assign i_vr.ready = r_ready && !check.stall;
  always@(posedge i_clock)begin
    if(i_reset) in_flush <= 0;
    else if(i_flush && !r_ready && !o_rq.valid && !in_flush) in_flush <= 1;
    else if(in_flush && o_rq.valid) in_flush <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) r_ready <= 1;
    else if (r_valid && r_ready && !check.hit && !i_flush) r_ready <= 0;
    else if (o_rq.valid && !r_ready) r_ready <= 1;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) o_rq.rq <= 0;
    else if (!o_rq.rq && r_valid && i_vr.ready && !check.hit && !i_flush) o_rq.rq <= 1;
    else if (o_rq.rq && o_rq.ack) o_rq.rq <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (r_valid && i_vr.ready && !i_flush) rq <= i_rq;
  end
  logic commit_valid;
  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush || in_flush) commit_valid <= 0 ;
    else if(o_rq.valid && !i_vr.ready || r_valid && i_vr.ready && check.hit) commit_valid <= 1;
    else if(commit_valid) commit_valid <= 0;
  end
  logic [31:0] rdata;
  logic [31:0] rdata_aligned;
  logic [1:0] aligned_addr;
  assign rdata = r_valid && i_vr.ready && check.hit ? check.data : o_rq.rdata;
  assign aligned_addr = r_valid && i_vr.ready && check.hit ? i_rq.addr[1:0] : rq.addr[1:0];
  always_comb begin
    unique case (aligned_addr)
      2'b00: begin
        rdata_aligned = rdata;
      end
      2'b01: begin
        rdata_aligned = {8'b0, rdata[31:8]};
      end
      2'b10: begin
        rdata_aligned = {16'b0, rdata[31:16]};
      end
      2'b11: begin
        rdata_aligned = {24'b0, rdata[31:24]};
      end
    endcase
  end
  
  logic [31:0] load_result, result;
  always_ff @(posedge i_clock) begin
    if (o_rq.valid && !in_flush || r_valid && i_vr.ready && check.hit && !i_flush) load_result <= rdata_aligned;
  end
  assign o_rq.addr = rq.addr;
  assign o_rq.read_t = rq.read_t;
  assign o_rq.ready = 1;

  rob::result_t wb_result;
  always_comb begin
    case (rq.read_t)
      3'b000:  result = {{24{load_result[7]}}, load_result[7:0]};
      3'b001:  result = {{16{load_result[15]}}, load_result[15:0]};
      3'b010:  result = load_result;
      3'b100:  result = {24'b0, load_result[7:0]};
      3'b101:  result = {16'b0, load_result[15:0]};
      default: result = load_result;
    endcase
  end
  assign wb_result.upc = 0;
  assign wb_result.btb_update = 0;
  assign wb_result.flush = 0;
  assign commit.result = wb_result;
  assign commit.valid = commit_valid;
  assign commit.index = rq.rob_index;

  assign check.addr = i_rq.addr;
  assign check.store_index = i_rq.store_index;
  assign check.read_t = i_rq.read_t;
  assign winfo.valid = commit_valid;
  assign winfo.wen = 1;
  assign winfo.rd = rq.rd;
  assign winfo.wdata = result;

  assign rename_commit.prd = rq.rd;
  assign rename_commit.vrd = rq.vrd;
  assign rename_commit.valid = commit_valid;
  logic mem_valid;
  assign mem_valid = (o_rq.valid && !i_vr.ready || r_valid && i_vr.ready && check.hit) && !i_flush && !in_flush;
  assign lsu_wakeup.valid = mem_valid;
  assign lsu_wakeup.prd = o_rq.valid && !i_vr.ready ? rq.rd : i_rq.rd;
`ifdef CONFIG_SIM
  function logic in_mem(input int addr);
`ifdef CONFIG_YSYXSOC
    return addr >= 32'h0f000000 && addr < 32'h0fffffff || addr >= 32'h30000000 && addr < 32'h3fffffff || addr >= 32'ha0000000 && addr < 32'hbfffffff;
`else
    return addr >= 32'h80000000 && addr < 32'h90000000;
`endif
  endfunction
  assign wb_result.sim.difftest_skip = !(rq.addr >= 32'h80000000 && rq.addr < 32'h90000000);
  assign wb_result.sim.addr = rq.addr;
  assign wb_result.sim.ren = 1;
`endif

endmodule
