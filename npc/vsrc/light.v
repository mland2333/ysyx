module light(
  input clock,
  input reset,
  output reg [15:0] led
);
  reg [31:0] count;
  always @(posedge clock) begin
    if (reset) begin led <= 1; count <= 0; end
    else begin
      if (count == 0) led <= {led[14:0], led[15]};
      count <= (count >= 5000000 ? 32'b0 : count + 1);
    end
  end
endmodule
