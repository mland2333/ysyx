module ysyx_24110006_LOAD_UNIT (
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_rq_load.out o_rq,
    input lsu::rq_load_t i_rq,
    output rob::commit_info_t commit,
    if_load_check.out check
);
  lsu::rq_load_t rq;
  logic in_flush;
  always@(posedge i_clock)begin
    if(i_reset) in_flush <= 0;
    else if(i_flush && !i_vr.ready && !o_rq.valid && !in_flush) in_flush <= 1;
    else if(in_flush && o_rq.valid) in_flush <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) i_vr.ready <= 1;
    else if (i_vr.valid && i_vr.ready && !check.hit && !i_flush) i_vr.ready <= 0;
    else if (o_rq.valid && !i_vr.ready) i_vr.ready <= 1;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) o_rq.rq <= 0;
    else if (!o_rq.rq && i_vr.valid && i_vr.ready && !check.hit && !i_flush) o_rq.rq <= 1;
    else if (o_rq.rq && o_rq.ack) o_rq.rq <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_vr.valid && i_vr.ready && !i_flush) rq <= i_rq;
  end
  assign o_rq.addr = rq.addr;
  logic commit_valid;
  always_ff@(posedge i_clock)begin
    if(i_reset || i_flush || in_flush) commit_valid <= 0 ;
    else if(o_rq.valid && !i_vr.ready || i_vr.valid && i_vr.ready && check.hit) commit_valid <= 1;
    else if(commit_valid) commit_valid <= 0;
  end
  logic [31:0] rdata;
  logic [31:0] rdata_aligned;
  assign rdata = i_vr.valid && i_vr.ready && check.hit ? check.data : o_rq.rdata;
  always_comb begin
    unique case (rq.addr[1:0])
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
    if (o_rq.valid && !in_flush || i_vr.valid && i_vr.ready && check.hit && !i_flush) load_result <= rdata_aligned;
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
  assign wb_result.result = result;
  assign wb_result.flush = 0;
  assign wb_result.upc = 0;
  assign commit.valid = commit_valid;
  assign commit.result = wb_result;
  assign commit.index = rq.rob_index;
  assign check.addr = i_rq.addr;
`ifdef CONFIG_SIM
  function logic in_mem(input int addr);
`ifdef CONFIG_YSYXSOC
    return addr >= 32'h0f000000 && addr < 32'h0fffffff || addr >= 32'h30000000 && addr < 32'h3fffffff || addr >= 32'ha0000000 && addr < 32'hbfffffff;
`else
    return addr >= 32'h80000000 && addr < 32'h90000000;
`endif
  endfunction
  assign wb_result.sim.difftest_skip = !in_mem(rq.addr);
  assign wb_result.sim.addr = rq.addr;
  assign wb_result.sim.ren = 1;
`endif

endmodule
