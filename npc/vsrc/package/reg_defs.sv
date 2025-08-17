`include "common_config"

package rf;

  typedef logic [`PREG_NUM_INDEX-1:0] preg;
  typedef logic [1:0][`PREG_NUM_INDEX-1:0] pregs;
  typedef logic [4:0] vreg;
  typedef logic [31:0] data;
  typedef struct packed {
    pregs rs;
    logic [1:0] rs_zero;
  } rinfo_t;
  typedef struct packed {
    logic valid, wen;
    preg rd;
    logic [31:0] wdata;
  } winfo_t;
  typedef struct packed {logic[1:0][31:0] d;} rdata_t;
endpackage
