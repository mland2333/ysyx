package bypass;

  typedef enum logic [1:0] {
    none,
    from_reg,
    from_int,
    from_lsu
  } src_loction;
  typedef struct packed {logic [1:0][1:0] loc;} src_loction_t;
  typedef struct packed {logic [31:0] r1, r2;} src_t;
  typedef struct packed {
    logic valid;
    rf::preg rd;
  } wakeup_t;
endpackage
