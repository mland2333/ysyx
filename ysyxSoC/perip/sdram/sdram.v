module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 1:0] dqm,
  inout [15:0] dq
);

typedef enum [2:0] { idle_t, mode_t, active_t, delay_t, read_t, write_t}state_t;

localparam CMD_ACTIVE        = 4'b0011;
localparam CMD_READ          = 4'b0101;
localparam CMD_WRITE         = 4'b0100;
localparam CMD_LOAD_MODE     = 4'b0000;

wire [3:0] cmd = {cs, ras, cas, we};
reg [8191:0] sdram0 [8192];
reg [8191:0] sdram1 [8192];
reg [8191:0] sdram2 [8192];
reg [8191:0] sdram3 [8192];
wire [8191:0] sdram_row [4];

reg [12:0] mode;
reg [12:0] row [4];
reg [1:0] bank;
reg [12:0] colnum;

wire [2:0] length = mode[2:0];
reg [2:0] tran_nums;
wire [7:0] latency = {5'b0, mode[6:4]};
reg [7:0] counter;
wire [7:0] wc = {5'b0, mode[2:0]};
wire [7:0] rc = {5'b0, mode[2:0]};

reg [1:0] wstrb;
reg [2:0] state;
always@(posedge clk)begin
  if(cke)begin
    case(state)
      idle_t: begin
        if(cmd == CMD_ACTIVE) state <= active_t;
        else if(cmd == CMD_LOAD_MODE) state <= mode_t;
        else if(cmd == CMD_WRITE) state <= write_t;
        else if(cmd == CMD_READ) state <= delay_t;
      end
      mode_t: state <= idle_t;
      active_t: begin
        if(cmd == CMD_WRITE) state <= write_t;
        else if(cmd == CMD_READ) state <= delay_t;
      end
      write_t: if(counter == wc) state <= idle_t;
      read_t: begin
        if(cmd == CMD_READ)
          state <= delay_t;
        else if(counter == rc) 
          state <= idle_t;
      end
      delay_t: if(counter == latency-1) state <= read_t;
      default: state <= idle_t;
    endcase
  end
end
always@(posedge clk)begin
  if(cmd == CMD_READ || cmd == CMD_WRITE) counter <= 0;
  else begin
    case(state)
      write_t: counter <= (counter == wc ? 0 : counter + 1);
      read_t : counter <= cmd == CMD_READ ? 0 : (counter == rc ? 0 : counter + 1);
      delay_t: counter <= (counter == latency-1 ? 0 : counter + 1);
      default: counter <= 0;
    endcase
  end
end


always@(posedge clk)begin
  if(cmd == CMD_LOAD_MODE)
    mode <= a;
end

always@(posedge clk)begin
  if(cmd == CMD_ACTIVE)
    row[ba] <= a;
end

always@(posedge clk)begin
  if((cmd == CMD_READ || cmd == CMD_WRITE))
    colnum <= {a[8:0], 4'b0};
end

always@(posedge clk)begin
  if(cmd == CMD_ACTIVE || cmd == CMD_READ || cmd == CMD_WRITE)
    bank <= ba;
end

always@(posedge clk)begin
  if(cmd == CMD_WRITE)
    wstrb <= dqm;
end

always@(posedge clk)begin
  if((state == write_t || state == read_t) && counter[2:0] == length)
    tran_nums <= 0;
  if((state == write_t || state == read_t || state == delay_t && counter == latency-1) && tran_nums != length )
    tran_nums <= tran_nums + 1;
end

wire [8191:0] sdram;
wire [15:0] rdata;
assign sdram_row[0] = sdram0[row[0]];
assign sdram_row[1] = sdram1[row[1]];
assign sdram_row[2] = sdram2[row[2]];
assign sdram_row[3] = sdram3[row[3]];
assign rdata = sdram_row[bank][colnum+tran_nums*16 +: 16];

reg [15:0] _wdata;
always@(posedge clk)begin
  if(cmd == CMD_WRITE)
    _wdata <= dq;
end

wire[15:0]  wdata00 = _wdata,
            wdata01 = {_wdata[15:8], rdata[7:0]},
            wdata10 = {rdata[15:8], _wdata[7:0]},
            wdata11 = rdata;

wire [15:0] wdata = wstrb == 2'b01 ? wdata01:
                    wstrb == 2'b10 ? wdata10:
                    wstrb == 2'b11 ? wdata11:
                    wdata00;

always@(posedge clk)begin
  if(state == write_t)begin
    case(bank)
      2'b00: sdram0[row[0]][colnum+tran_nums*16 +: 16] <= wdata;
      2'b01: sdram1[row[1]][colnum+tran_nums*16 +: 16] <= wdata;
      2'b10: sdram2[row[2]][colnum+tran_nums*16 +: 16] <= wdata;
      2'b11: sdram3[row[3]][colnum+tran_nums*16 +: 16] <= wdata;
    endcase
  end
end

  assign dq = state == read_t || state == delay_t ? rdata : 16'bz;

endmodule
