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
    mstd::vector#(bit) history;
    function new(int _pc, bit pred_taken);
      pc = _pc;
      history = new();
      history.push_back(pred_taken);
    endfunction
  endclass


  class BpHistory;
    mstd::vector#(BpHistoryEntry) history;

    function int find(int pc);
      for(int i = 0; i<history.size; i++) begin
        if (history.data[i].pc == pc) return i;
      end
      return -1;
    endfunction
    function new();
      history = new();
    endfunction
    function automatic void update(int pc, bit pred_taken);
      int index;
      index = find(pc);
      if (index != -1) history.data[index].history.push_back(pred_taken);
      else begin
        BpHistoryEntry entry = new(pc, pred_taken);
        history.push_back(entry);
      end
    endfunction
    function void print();
      for (int i=0; i<history.size; i++) begin
        $write("0x%x: ", history.data[i].pc);
        for (int j=0; j<history.data[i].history.size; j++) begin
          $write("%b", history.data[i].history.data[j]);
        end
        $display();
      end
    endfunction
  endclass
endpackage
