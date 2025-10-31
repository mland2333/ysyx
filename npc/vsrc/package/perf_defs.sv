package perf;
  typedef enum {
    branch,
    jal,
    PERF_BPU_COUNT
  } type_t;
  typedef struct packed {
    logic [31:0] pred_right, pred_wrong, unpred_right, unpred_wrong;
  } bpu_single_t;
  typedef struct packed {bpu_single_t [1:0] d;} bpu_t;
  class BpHistoryEntry;
    int pc;
    int hit_num, num;
    mstd::vector #(bit) pred_history;
    mstd::vector #(bit) real_history;
    mstd::vector #(bit) result_history;
    function new(int _pc, bit pred_taken, bit taken);
      pc = _pc;
      hit_num = bit'(pred_taken == taken);
      num = 1;
      pred_history = new();
      real_history = new();
      result_history = new();
      pred_history.push_back(pred_taken);
      real_history.push_back(taken);
      result_history.push_back(bit'(pred_taken == taken));
    endfunction
    function void update(bit pred_taken, bit taken);
      pred_history.push_back(pred_taken);
      real_history.push_back(taken);
      result_history.push_back(bit'(pred_taken == taken));
      hit_num += bit'(pred_taken == taken);
      num++;
    endfunction
    function void print();
      $write("0x%x num=%d hit_num=%d hit_rate=%f ", pc, num, hit_num, real'(hit_num) / real'(num));
      for(int i=0; i<pred_history.size; i++)
        $write("%b",pred_history.data[i]);
      $display();
      for(int i=0; i<real_history.size; i++)
        $write("%b",real_history.data[i]);
      $display();
      for(int i=0; i<result_history.size; i++)
        $write("%b",result_history.data[i]);
      $display();
    endfunction
  endclass


  class BpHistory;
    mstd::vector #(BpHistoryEntry) history;

    function int find(int pc);
      for (int i = 0; i < history.size; i++) begin
        if (history.data[i].pc == pc) return i;
      end
      return -1;
    endfunction
    function new();
      history = new();
    endfunction
    function automatic void update(int pc, bit pred_taken, taken);
      int index;
      index = find(pc);
      if (index != -1) begin
        history.data[index].update(pred_taken, taken);
      end else begin
        BpHistoryEntry entry = new(pc, pred_taken, taken);
        history.push_back(entry);
      end
    endfunction
    function void print();
      for (int i = 0; i < history.size; i++) begin
        history.data[i].print();
      end
    endfunction
  endclass
endpackage
