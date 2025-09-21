package npc.ifu

import chisel3._
import chisel3.util._
import chisel3.BlackBox
import chisel3.util.HasBlackBoxInline


class DpiIFU extends BlackBox with HasBlackBoxInline {
  val io = IO(new Bundle{
    val pc = Input(UInt(32.W))
    val inst = Output(UInt(32.W))
    val reset = Input(Bool())
  })

  setInline("DpiIFU.sv",
    s"""
    module DpiIFU(
      input reset,
      input [31:0] pc,
      output logic [31:0] inst
    );
      import \"DPI-C\" function int fetch_inst(input int pc);

      always @(pc or reset) begin
        if(!reset) inst = fetch_inst(pc);
      end
    endmodule
    """)
}
class IFU(reset_vector:UInt) extends Module{
  val io = IO(new Bundle{
    val upc = Input(UInt(32.W))
    val jump = Input(Bool())
    val inst = Output(UInt(32.W))
    val pc = Output(UInt(32.W))
  })
  val pc_plus_4 = Wire(UInt(32.W))
  val pc_next = Wire(UInt(32.W))
  val pc = RegInit(reset_vector)
  pc_plus_4 := pc + 4.U
  pc_next := Mux(io.jump, io.upc, pc_plus_4)

  when(reset.asBool){
    pc := reset_vector;
  }.otherwise{
    pc := pc_next;
  }
  pc := pc_next
  io.pc := pc
  val ifu = Module(new DpiIFU())
  ifu.io.reset := reset.asBool
  ifu.io.pc := pc
  io.inst := ifu.io.inst 
}
