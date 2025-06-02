module ysyx_24110006_FIFO

//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH  = 8,
    parameter DEPTH  = 4,
    parameter ADDR_W = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
      input             clk_i
    , input             rst_i
    , input [WIDTH-1:0] data_in_i
    , input             push_i
    , input             pop_i

    // Outputs
    , output [WIDTH-1:0] data_out_o
    , output             accept_o
    , output             valid_o
);

  //-----------------------------------------------------------------
  // Local Params
  //-----------------------------------------------------------------
  localparam COUNT_W = ADDR_W + 1;

  //-----------------------------------------------------------------
  // Registers
  //-----------------------------------------------------------------
  reg [  WIDTH-1:0] ram    [DEPTH-1:0];
  reg [ ADDR_W-1:0] rd_ptr;
  reg [ ADDR_W-1:0] wr_ptr;
  reg [COUNT_W-1:0] count;

  //-----------------------------------------------------------------
  // Sequential
  //-----------------------------------------------------------------
  always @(posedge clk_i or posedge rst_i)
    if (rst_i) begin
      count  <= {(COUNT_W) {1'b0}};
      rd_ptr <= {(ADDR_W) {1'b0}};
      wr_ptr <= {(ADDR_W) {1'b0}};
    end else begin
      // Push
      if (push_i & accept_o) begin
        ram[wr_ptr] <= data_in_i;
        wr_ptr      <= wr_ptr + 1;
      end

      // Pop
      if (pop_i & valid_o) rd_ptr <= rd_ptr + 1;

      // Count up
      if ((push_i & accept_o) & ~(pop_i & valid_o)) count <= count + 1;
      // Count down
      else if (~(push_i & accept_o) & (pop_i & valid_o)) count <= count - 1;
    end

  //-------------------------------------------------------------------
  // Combinatorial
  //-------------------------------------------------------------------
  /* verilator lint_off WIDTH */
  assign accept_o   = (count != DEPTH);
  assign valid_o    = (count != 0);
  /* verilator lint_on WIDTH */

  assign data_out_o = ram[rd_ptr];

endmodule
