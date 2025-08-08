package rename;

  typedef struct packed{
    logic valid;
    rf::preg prd;
    rf::vreg vrd;
  }commit_t;
  typedef struct packed{
    logic valid, flush, has_old_map;
    rf::preg prd;
    rf::preg old_index;
    rf::vreg vrd;
  }retire_t;

endpackage
