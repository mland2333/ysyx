`include "common_config.sv"
package rename;

  typedef struct packed {
    logic valid;
    rf::preg prd;
    rf::vreg vrd;
  } commit_t;
  localparam COMMIT_COUNT = 3;
  typedef struct packed {commit_t [COMMIT_COUNT-1:0] d;} commit_group_t;
  typedef struct packed {
    logic valid, flush, has_old_map;
    rf::preg prd;
    rf::preg old_index;
    rf::vreg vrd;
  } retire_t;
  localparam RETIRE_COUNT = 2;
  typedef struct packed {retire_t [RETIRE_COUNT-1:0] d;} retire_group_t;
  typedef struct packed {
    logic w_prior, r_prior;
    logic [`PREG_NUM_INDEX-2:0] w_ptr, r_ptr;
    logic [`PREG_NUM_INDEX:0] count;
    logic [`PREG_NUM/2-1:0][`PREG_NUM_INDEX-1:0] fifo1, fifo2;
  } free_list_backup_t;
endpackage
