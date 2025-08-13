module ysyx_24110006_STORE_BUFFER#(
    parameter STORE_BUFFER_NUM = 4
)(
    input i_clock,
    input i_reset,
    input i_flush,
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr,
    input lsu::rq_store_t i_rq,
    input store_retire,
    if_load_check.in check,
    output lsu::rq_store_t o_rq,
    input store_finish
);
  localparam BUFFER_INDEX = $clog2(STORE_BUFFER_NUM);
  lsu::rq_store_t buffer[STORE_BUFFER_NUM];
  logic [BUFFER_INDEX-1:0] w_ptr, r_ptr;
  logic [BUFFER_INDEX:0] count;
  logic [BUFFER_INDEX-1:0] retire_ptr, active_ptr;
  logic [BUFFER_INDEX:0] retire_count;
  logic full, empty;
  logic push, pop;
  logic [STORE_BUFFER_NUM-1:0] rq_valid, rq_retire, check_valid;
  assign full  = count == BUFFER_INDEX;
  assign empty = count == 0;
  assign push  = i_vr.valid && i_vr.ready;
  assign pop   = store_finish;
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      w_ptr <= 0;
      r_ptr <= 0;
      count <= 0;
    end else if(i_flush)begin
      w_ptr <= retire_ptr;
      count <= store_finish ? retire_count - 1 : retire_count;
      r_ptr <= store_finish ? r_ptr + 1 : r_ptr;
    end else if (push && pop) begin
      w_ptr <= w_ptr + 1;
      r_ptr <= r_ptr + 1;
    end else if (push) begin
      w_ptr <= w_ptr + 1;
      count <= count + 1;
    end else if (pop) begin
      r_ptr <= r_ptr + 1;
      count <= count - 1;
    end
  end
  always_ff@(posedge i_clock)begin
    if(i_reset) retire_ptr <= 0;
    else if(store_retire) retire_ptr <= retire_ptr + 1;
  end
  always_ff@(posedge i_clock)begin
    if(i_reset) active_ptr <= 0;
    else if(o_vr.valid && o_vr.ready) active_ptr <= active_ptr + 1;
  end
  always_ff@(posedge i_clock)begin
    if(i_reset) retire_count <= 0;
    else if(!(store_retire && store_finish))begin
      if(store_retire) retire_count <= retire_count + 1;
      else if(store_finish) retire_count <= retire_count - 1;
    end
  end
  always_ff @(posedge i_clock) begin
    if (push) buffer[w_ptr] <= i_rq;
  end
  
  always_ff@(posedge i_clock)begin
    if(i_reset) rq_valid <= 0;
    else if(i_flush) rq_valid <= rq_retire;
    else if(push && pop) begin
      rq_valid[w_ptr] <= 1;
      rq_valid[r_ptr] <= 0;
    end
    else if(push) rq_valid[w_ptr] <= 1;
    else if(pop) rq_valid[r_ptr] <= 0;
  end
  always_ff@(posedge i_clock)begin
    if(i_reset) rq_retire <= 0;
    else if(store_retire && store_finish) begin
      rq_retire[retire_ptr] <= 1;
      rq_retire[r_ptr] <= 0;
    end
    else if(store_retire) rq_retire[retire_ptr] <= 1;
    else if(store_finish) rq_retire[r_ptr] <= 0;
  end

  assign i_vr.ready = !full;
  assign o_vr.valid = rq_retire[active_ptr];
  assign o_rq = buffer[active_ptr];
  typedef struct packed {
    logic valid;
    rob::wb_index age;
    logic [BUFFER_INDEX-1:0] index;
  } entry_t;
  entry_t nodes[STORE_BUFFER_NUM*2];
  always_comb begin
    for(int i = 0; i<STORE_BUFFER_NUM; i++)begin
      check_valid[i] = (check.store_index == buffer[i].rob_index ||
        rob::is_older(buffer[i].rob_index, check.store_index)) &&
        check.addr == buffer[i].addr &&
        rq_valid[i];
    end
  end
  generate
    for (genvar i = 0; i < STORE_BUFFER_NUM; i++) begin : leaf_init
      always_comb begin
        nodes[i+STORE_BUFFER_NUM].valid = check_valid[i];
        nodes[i+STORE_BUFFER_NUM].age   = buffer[i].rob_index;
        nodes[i+STORE_BUFFER_NUM].index = (BUFFER_INDEX)'(i);
      end
    end
  endgenerate

  generate
    for (genvar level = 0; level < $clog2(STORE_BUFFER_NUM); level++) begin : tree_level
      for (genvar j = (1 << level); j < (1 << (level + 1)); j++) begin : tree_node
        select_younger_age #(
            .T(entry_t),
            .C(rob::wb_index)
        ) younger(
            .a(nodes[j*2]), .b(nodes[j*2+1]), .select(nodes[j])
        );
      end
    end
  endgenerate
  assign check.hit = nodes[1].valid;
  assign check.data = buffer[nodes[1].index].wdata;
endmodule
