module top(
  input clock,
  input reset,
  output[15:0] led
);
light mlight(
  .clock(clock),
  .reset(reset),
  .led(led)
);

endmodule
