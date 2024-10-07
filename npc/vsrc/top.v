module top(
  input clock,
  input reset,
  output [15:0] led
);

Light light(
  .clock(clock),
  .reset(reset),
  .led(led)
);
endmodule
