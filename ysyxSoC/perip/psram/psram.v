module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);

typedef enum [2:0] { mode_t, qpi_t, cmd_t, addr_t, delay_t, read_t, write_t } state_t;
reg[7:0] psram[2**24];
reg [2:0] state;
reg [7:0] counter;
reg [7:0] cmd;
wire is_write = cmd == 8'h38;
reg [23:0] addr;
reg [31:0] rdata;
reg [31:0] wdata;

always@(posedge sck or posedge ce_n)begin
  if(ce_n)begin
    state <= mode_t;
  end
  else begin
    case(state)
      mode_t: if(counter == 8'd1) state <= dio == 4'b0001 ? qpi_t : cmd_t;
      qpi_t : if(counter == 8'd1) state <= addr_t;
      cmd_t: if(counter == 8'd7) state <= addr_t;
      addr_t: if(counter == 8'd5) state <= is_write ? write_t : delay_t;
      delay_t: if(counter == 8'd6) state <= read_t;
      write_t: state <= state;
      read_t: state <= state;
      default : state <= cmd_t;
    endcase
  end
end

always@(posedge sck or posedge ce_n)begin
  if(ce_n)begin
    counter <= 0;
  end
  else begin
    case(state)
      mode_t:  counter <= (counter < 8'd1 ) ? counter + 8'd1 : 8'd0;
      qpi_t:   counter <= (counter < 8'd1 ) ? counter + 8'd1 : 8'd0;
      cmd_t:   counter <= (counter < 8'd7 ) ? counter + 8'd1 : 8'd0;
      addr_t:  counter <= (counter < 8'd5 ) ? counter + 8'd1 : 8'd0;
      delay_t: counter <= (counter < 8'd6 ) ? counter + 8'd1 : 8'd0;
      write_t: counter <= counter + 8'd1;
      read_t:  counter <= counter + 8'd1;
      default: counter <= counter;
    endcase
  end
end

always@(posedge sck or posedge ce_n)begin
  if(ce_n)begin
    cmd <= 0;
  end
  else begin
    if(state == qpi_t) cmd <= {cmd[3:0], dio};
    else if(state == cmd_t) cmd <= {cmd[6:0], dio[0]};
  end
end

always@(posedge sck or posedge ce_n)begin
  if(ce_n)begin
    addr <= 0;
  end
  else begin
    if(state == addr_t) addr <= {addr[19:0], dio};
  end
end
wire[31:0] bswap_wdata = {wdata[27:24], wdata[31:28], wdata[19:16], wdata[23:20], wdata[11:8], wdata[15:12], wdata[3:0], wdata[7:4]};

always@(posedge sck or posedge ce_n)begin
  if(ce_n)begin
    if(state == write_t)begin
        if(counter == 8'd8)begin
          psram[{addr[23:2], 2'b00}] <= bswap_wdata[7:0];
          psram[{addr[23:2], 2'b01}] <= bswap_wdata[15:8];
          psram[{addr[23:2], 2'b10}] <= bswap_wdata[23:16];
          psram[{addr[23:2], 2'b11}] <= bswap_wdata[31:24];
        end
        else if(counter == 8'd4)begin
          psram[{addr[23:1], 1'b0}] <= bswap_wdata[23:16];
          psram[{addr[23:1], 1'b1}] <= bswap_wdata[31:24];
        end
        else if(counter == 8'd2)begin
          psram[addr] <= bswap_wdata[31:24];
        end
      end
      wdata <= 32'd0;
  end
  else begin
    if(state == write_t) wdata <= {dio, wdata[31:4]}; 
  end
end
wire[31:0] bswap_rdata = {rdata[27:24], rdata[31:28], rdata[19:16], rdata[23:20], rdata[11:8], rdata[15:12], rdata[3:0], rdata[7:4]};
/* wire[31:0] bswap_rdata = {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]}; */
/* wire [31:0] bswap_rdata = rdata; */
always@(posedge sck or posedge ce_n)begin
  if(ce_n)begin
    rdata <= 0;
  end
  else begin
    if(state == delay_t && counter == 8'd5)begin
      rdata[7:0]   <= psram[{addr[23:2], 2'b00}];
      rdata[15:8]  <= psram[{addr[23:2], 2'b01}];
      rdata[23:16] <= psram[{addr[23:2], 2'b10}];
      rdata[31:24] <= psram[{addr[23:2], 2'b11}];
    end
  end
end

  assign dio = state == read_t && counter < 8 ? bswap_rdata[(counter)*4 +: 4] : 4'bz;

endmodule
