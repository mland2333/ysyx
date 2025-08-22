module PHT #(
    NUM = 32
) (
    input i_clock,
    input i_reset,
    input bp::update_pht_t update,
    if_rq_pht.in i_rq
);
  typedef enum logic [1:0] {
    strong_nt,
    weak_nt,
    strong_t,
    weak_t
  } fsm;
  fsm pht[NUM];
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM; i++) begin
      if (i_reset) pht[i] <= weak_nt;
      else if (update.valid && update.index == i) begin
        case (pht[i])
          strong_nt: begin
            if (update.taken) pht[i] <= weak_nt;
          end
          weak_nt: begin
            if (update.taken) pht[i] <= weak_t;
            else pht[i] <= strong_nt;
          end
          weak_t: begin
            if (update.taken) pht[i] <= strong_t;
            else pht[i] <= weak_nt;
          end
          strong_t: begin
            if (!update.taken) pht[i] <= weak_t;
          end
        endcase
      end
    end
  end
  assign i_rq.pred_taken = pht[i_rq.index][1];

endmodule
