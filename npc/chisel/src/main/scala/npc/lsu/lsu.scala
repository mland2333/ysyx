package npc.lsu

import chisel3._
import chisel3.util._

class DpiMemIO extends Bundle {
  val wen   = Input(Bool())
  val ren   = Input(Bool())
  val addr  = Input(UInt(32.W))
  val wdata = Input(UInt(32.W))
  val rdata = Output(UInt(32.W))
  val wmask = Input(UInt(4.W))
}

class DpiMem extends BlackBox with HasBlackBoxInline {
  val io = IO(new DpiMemIO)

  setInline("DpiMem.sv",
    s"""
    module DpiMem(
      input        wen,
      input        ren,
      input [31:0] addr,
      input [31:0] wdata,
      output logic [31:0] rdata,
      input [3:0]  wmask
    );
      import \"DPI-C\" function int pmem_read(input int raddr);
      import \"DPI-C\" function void pmem_write(input int waddr, input int wdata, input byte wmask);

      always @(ren or addr) begin
        if (ren) begin
          rdata = pmem_read(addr);
        end
      end

      always @(wen or addr or wdata or wmask) begin
        if (wen) begin
          pmem_write(addr, wdata, wmask);
        end
      end
    endmodule
    """)
}
class LsuIO extends Bundle{
    val wen = Input(Bool())
    val ren = Input(Bool())
    val addr = Input(UInt(32.W))
    val wdata = Input(UInt(32.W))
    val wmask = Input(UInt(4.W))
    val read_type = Input(UInt(3.W))
}
class LSU extends Module{
    val io = IO(new Bundle{
        val lsuIO = new LsuIO
        val rdata = Output(UInt(32.W))
    })
    val mem = Module(new DpiMem())
    mem.io.wen := io.lsuIO.wen
    mem.io.ren := io.lsuIO.ren
    mem.io.addr := io.lsuIO.addr
    mem.io.wdata := io.lsuIO.wdata
    mem.io.wmask := io.lsuIO.wmask
    val rdata = mem.io.rdata
    val rdata_aligned = WireDefault(0.U(32.W))
    switch(io.lsuIO.addr(1,0)){
        is("b00".U){
            rdata_aligned := rdata
        }
        is("b01".U){
            rdata_aligned := Cat(Fill(8, 0.U(1.W)), rdata(31,8))
        }
        is("b10".U){
            rdata_aligned := Cat(Fill(16, 0.U(1.W)), rdata(31,16))
        }
        is("b11".U){
            rdata_aligned := Cat(Fill(24, 0.U(1.W)), rdata(31,24))
        }
    }
    io.rdata := 0.U(32.W)
    switch(io.lsuIO.read_type){
        is("b000".U){
            io.rdata := Cat(Fill(24, rdata_aligned(7)), rdata_aligned(7,0))
        }
        is("b001".U){
            io.rdata := Cat(Fill(16, rdata_aligned(15)), rdata_aligned(15,0))
        }
        is("b010".U){
            io.rdata := rdata_aligned
        }
        is("b100".U){
            io.rdata := Cat(Fill(24, 0.U(1.W)), rdata_aligned(7,0))
        }
        is("b101".U){
            io.rdata := Cat(Fill(16, 0.U(1.W)), rdata_aligned(15,0))
        }
    }
}
