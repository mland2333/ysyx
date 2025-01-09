// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
//`define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else
wire is_flash = in_paddr[29];

localparam INST = 3'b001;
localparam DIVI = 3'b010;
localparam SS = 3'b011;
localparam CTRL = 3'b100;
localparam GO_BUSY = 3'b101;
localparam WAIT = 3'b110;
localparam READ = 3'b111;

reg[2:0] state;
wire[31:0] prdata;
reg [4:0] flash_addr;
reg [31:0] flash_wdata;
wire is_write;
reg is_ready;
reg is_wait;

always@(posedge clock)begin
  if(reset) is_wait <= 1;
  else begin
    if(state == WAIT) is_wait <= 0;
    else is_wait <= 1;
  end
end

always@(posedge clock)begin
  if(reset) state <= INST;
  else begin
    case(state)
      INST: if(in_penable && pready && is_flash) state <= DIVI;
      DIVI: state <= SS;
      SS : state <= CTRL;
      CTRL: state <= GO_BUSY;
      GO_BUSY : state <= WAIT;
      WAIT: if(!is_wait && !prdata[8]) state <= READ;
      READ: if(~in_penable) state <= INST;
      default: state <= INST;
    endcase
  end
end

always@(*)begin
  case(state)
    INST: flash_addr = 5'h04;
    DIVI: flash_addr = 5'h14;
    SS: flash_addr = 5'h18;
    CTRL: flash_addr = 5'h10;
    GO_BUSY: flash_addr = 5'h10;
    WAIT: flash_addr = 5'h10;
    READ: flash_addr = 5'h0;
    default : flash_addr = 5'h0;
  endcase
end

always@(*)begin
  case(state)
    INST: flash_wdata = {8'h03, in_paddr[23:0]};
    DIVI: flash_wdata = 32'h2;
    SS: flash_wdata = 32'h1;
    CTRL: flash_wdata = 32'h2040;
    GO_BUSY: flash_wdata = 32'h2140;
    default : flash_wdata = 32'h0;
  endcase
end

assign is_write = state != WAIT && state != READ;

always@(posedge clock)begin
  if(reset) is_ready <= 0;
  else begin
    if(penable && is_ready) is_ready <= 0;
    else if(penable && state == READ) is_ready <= 1;
  end
end

wire [4:0] paddr = is_flash ? flash_addr : in_paddr[4:0];
wire [31:0] pwdata = is_flash ? flash_wdata : in_pwdata;
wire [31:0] flash_rdata = {prdata[7:0], prdata[15:8], prdata[23:16], prdata[31:24]};
assign in_prdata = is_flash ? flash_rdata : prdata;
wire pwrite = is_flash ? is_write : in_pwrite;
wire [3:0] pstrb = is_flash ? 4'hf : in_pstrb;
wire psel = in_psel;
wire penable = in_penable;
assign in_pready = is_flash ? is_ready : pready;
wire pready;

spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(paddr),
  .wb_dat_i(pwdata),
  .wb_dat_o(prdata),
  .wb_sel_i(pstrb),
  .wb_we_i (pwrite),
  .wb_stb_i(psel),
  .wb_cyc_i(penable),
  .wb_ack_o(pready),
  .wb_err_o(in_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

`endif // FAST_FLASH

endmodule
