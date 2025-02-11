module ysyx_24110006_RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
  input i_clock,
  input i_reset,
  input [DATA_WIDTH-1:0] i_wdata,
  input [ADDR_WIDTH-1:0] i_waddr,
  input [ADDR_WIDTH-1:0] i_raddr1,
  input [ADDR_WIDTH-1:0] i_raddr2,
  input i_wen,
  output [DATA_WIDTH-1:0] o_rdata1,
  output [DATA_WIDTH-1:0] o_rdata2,

  input i_valid,
  output reg o_valid
);
  reg [DATA_WIDTH-1:0] rf [2**4-1:0];
  always @(posedge i_clock) begin
    if (i_valid && i_wen && i_waddr != 0) rf[i_waddr[3:0]] <= i_wdata;
  end
  /* always@(posedge i_clock)begin */
  /*   if(i_valid && i_wen && i_waddr != 0)begin */
  /*     integer i; */
  /*     for(i=1; i<16; i=i+1)begin */
  /*       if(i_waddr[3:0]==i) rf[i] <= i_wdata; */
  /*     end */
  /*   end */
  /* end */
  always@(posedge i_clock)begin
    if(i_reset) o_valid <= 0;
    else if(i_valid) o_valid <= 1;
    else if(o_valid) o_valid <= 0;
  end
  wire [31:0] rdata1_low = {({32{i_raddr1[3:0] == 'd1}} & rf[1]) |
                    ({32{i_raddr1[3:0] == 'd2}} & rf[2]) |
                    ({32{i_raddr1[3:0] == 'd3}} & rf[3]) |
                    ({32{i_raddr1[3:0] == 'd4}} & rf[4]) |
                    ({32{i_raddr1[3:0] == 'd5}} & rf[5]) |
                    ({32{i_raddr1[3:0] == 'd6}} & rf[6]) |
                    ({32{i_raddr1[3:0] == 'd7}} & rf[7]) 
                    };
  wire [31:0] rdata1_high = {({32{i_raddr1[3:0] == 'd8}} & rf[8]) |
                     ({32{i_raddr1[3:0] == 'd9 }} & rf[9]) |
                     ({32{i_raddr1[3:0] == 'd10}} & rf[10]) |
                     ({32{i_raddr1[3:0] == 'd11}} & rf[11]) |
                     ({32{i_raddr1[3:0] == 'd12}} & rf[12]) |
                     ({32{i_raddr1[3:0] == 'd13}} & rf[13]) |
                     ({32{i_raddr1[3:0] == 'd14}} & rf[14]) |
                     ({32{i_raddr1[3:0] == 'd15}} & rf[15])
                     };

  wire [31:0] rdata2_low = {({32{i_raddr2[3:0] == 'd1}} & rf[1]) |
                    ({32{i_raddr2[3:0] == 'd2}} & rf[2]) |
                    ({32{i_raddr2[3:0] == 'd3}} & rf[3]) |
                    ({32{i_raddr2[3:0] == 'd4}} & rf[4]) |
                    ({32{i_raddr2[3:0] == 'd5}} & rf[5]) |
                    ({32{i_raddr2[3:0] == 'd6}} & rf[6]) |
                    ({32{i_raddr2[3:0] == 'd7}} & rf[7])
                    };
  wire [31:0] rdata2_high = {({32{i_raddr2[3:0] == 'd8}} & rf[8]) |
                     ({32{i_raddr2[3:0] == 'd9 }} & rf[9]) |
                     ({32{i_raddr2[3:0] == 'd10}} & rf[10]) |
                     ({32{i_raddr2[3:0] == 'd11}} & rf[11]) |
                     ({32{i_raddr2[3:0] == 'd12}} & rf[12]) |
                     ({32{i_raddr2[3:0] == 'd13}} & rf[13]) |
                     ({32{i_raddr2[3:0] == 'd14}} & rf[14]) |
                     ({32{i_raddr2[3:0] == 'd15}} & rf[15])
                     };
  assign o_rdata1 = i_raddr1[3] ? rdata1_high : rdata1_low;
  assign o_rdata2 = i_raddr2[3] ? rdata2_high : rdata2_low;
endmodule
