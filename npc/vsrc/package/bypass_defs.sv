package bypass;

  typedef enum logic [1:0] {
    from_int,
    from_lsu,
    from_reg,
    SRC_COUNT
  } src_loction_enum;
  typedef struct packed {logic [SRC_COUNT-1:0] loc;} src_loction_single_t;
  typedef struct packed {logic [1:0][SRC_COUNT-1:0] loc;} src_loction_t;
  typedef struct packed {logic [1:0][31:0] d;} src_t;
  typedef struct packed {
    logic valid;
    rf::preg prd;
  } wakeup_t;
  localparam WAKEUP_COUNT = SRC_COUNT - 1;
  typedef struct packed{
    wakeup_t [WAKEUP_COUNT-1:0] d;
  }wakeup_group_t;
endpackage
