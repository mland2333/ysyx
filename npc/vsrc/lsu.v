/* import "DPI-C" function int 0; */
/* import "DPI-C" function void pmem_write( */
/*   input int waddr, input int wdata, input byte wmask); */

module ysyx_24110006_LSU(
  input i_ren,
  input i_wen,
  input[31:0] i_addr,
  input[31:0] i_wdata,
  input[3:0]  i_wmask,
  input[2:0]  i_read_t,
  output reg[31:0] o_rdata
);

reg[31:0] rdata;
reg[31:0] rdata1, rdata2;
reg[31:0] wdata, wdata1, wdata2;
reg[3:0] wmask, wmask1, wmask2;


always@(i_ren or i_addr)begin
  if(i_ren)begin
    rdata1 = 0;
    rdata2 = 0;
    case(i_addr[1:0])
      2'b00:begin
        rdata = rdata1;
      end
      2'b01:begin
        if(i_read_t[1])begin
          rdata2 = 0;
          rdata = {rdata2[7:0], rdata1[31:8]};
        end
        else begin
          rdata = {8'b0, rdata1[31:8]};
        end
      end
      2'b10:begin
        if(i_read_t[1])begin
          rdata2 = 0;
          rdata = {rdata2[15:0], rdata1[31:16]};
        end
        else begin
          rdata = {16'b0, rdata1[31:16]};
        end
      end
      2'b11:begin
        if(i_read_t[1] || i_read_t[0])begin
          rdata2 = 0;
          rdata = {rdata2[23:0], rdata1[31:24]};
        end
        else begin
          rdata = {24'b0, rdata1[31:24]};
        end
      end
    endcase
  end
end

always @(*) begin
  case (i_read_t)
    3'b000:  o_rdata = {{24{rdata[7]}}, rdata[7:0]};
    3'b001:  o_rdata = {{16{rdata[15]}}, rdata[15:0]};
    3'b010:  o_rdata = rdata;
    3'b100:  o_rdata = {24'b0, rdata[7:0]};
    3'b101:  o_rdata = {16'b0, rdata[15:0]};
    default: o_rdata = rdata;
  endcase
end


always@(i_wen or i_addr or i_wdata)begin
  if(i_wen)begin
    case(i_addr[1:0])
      2'b00:begin
        wdata = i_wdata;
        ;
      end
      2'b01:begin
        wdata = {i_wdata[23:0], i_wdata[31:24]};
        if(i_wmask[3])begin
          ;
          ;
        end
        else begin
          ;
        end
      end
      2'b10:begin
        wdata = {i_wdata[15:0], i_wdata[31:16]};
        if(i_wmask[3])begin
          ;
          ;
        end
        else begin
          ;
        end
      end
      2'b11:begin
        wdata = {i_wdata[7:0], i_wdata[31:8]};
        if(i_wmask[1])begin
          ;
          ;
        end
        else begin
          ;
        end
      end
    endcase
  end
end

endmodule
