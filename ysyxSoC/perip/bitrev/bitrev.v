module bitrev (
  input  sck,
  input  ss,
  input  mosi,
  output miso
);
reg [7:0] data;
reg [4:0] count;
reg [1:0] state;
reg out;
assign miso = count >= 8 && ~ss ? data[0] : 1;
always@(negedge sck)begin
  if(count < 7) begin
    data <= {data[6:0], mosi};
    count <= count + 1;
  end
  else if(count == 7)begin
    count <= count + 1;
  end
  else if(count < 15) begin
    data <= {1'b0, data[7:1]};
    count <= count + 1;
  end
  else if(count == 15) begin
    count <= 0;
    data <= {1'b0, data[7:1]};
  end
end

endmodule
