package npc.idu

import chisel3._
import chisel3.util._
import chisel3.Bundle
import npc.reg.RegFileRaddrIO
object InstType extends ChiselEnum{
    val R, I, S, B, U, L, JAL, JALR, LUI, AUIPC, CSR, FENCEI = Value
}

object Decoder {
  def apply(inst: UInt): InstType.Type = {
    val result = WireDefault(InstType.R)
    val op = inst(6, 0)
    when(op === "b0110011".U) { result := InstType.R }
    .elsewhen(op === "b0010011".U) { result := InstType.I }
    .elsewhen(op === "b0000011".U) { result := InstType.L }
    .elsewhen(op === "b1100111".U) { result := InstType.JALR }
    .elsewhen(op === "b0100011".U) { result := InstType.S }
    .elsewhen(op === "b1100011".U) { result := InstType.B }
    .elsewhen(op === "b0110111".U) { result := InstType.LUI }
    .elsewhen(op === "b0010111".U) { result := InstType.AUIPC }
    .elsewhen(op === "b1110011".U) { result := InstType.CSR }
    .elsewhen(op === "b0001111".U) { result := InstType.FENCEI }
    .elsewhen(op === "b1101111".U) { result := InstType.JAL }
    .otherwise { result := InstType.R }
    
    result
  }
}

class ImmGen extends Module {
  val io = IO(new Bundle {
    val inst = Input(UInt(32.W))  // 添加指令输入
    val instType = Input(InstType())
    val imm = Output(UInt(32.W))
  })
  
  val iImm = Cat(Fill(20, io.inst(31)), io.inst(31, 20))
  val sImm = Cat(Fill(20, io.inst(31)), io.inst(31, 25), io.inst(11, 7))
  val bImm = Cat(Fill(19, io.inst(31)), io.inst(31), io.inst(7), io.inst(30, 25), io.inst(11, 8), 0.U(1.W))
  val jImm = Cat(Fill(11, io.inst(31)), io.inst(31), io.inst(19, 12), io.inst(20), io.inst(30, 21), 0.U(1.W))
  val rImm = Cat(Fill(25, 0.U(1.W)), io.inst(31, 25))
  val uImm = Cat(io.inst(31, 12), Fill(12, 0.U(1.W)))
  val imm = WireDefault(0.U(32.W))
  switch(io.instType){
    is(InstType.I){
      imm := iImm
    }
    is(InstType.L){
      imm := iImm
    }
    is(InstType.JALR){
      imm := iImm
    }
    is(InstType.LUI){
      imm := uImm
    }
    is(InstType.AUIPC){
      imm := uImm
    }
    is(InstType.S){
      imm := sImm
    }
    is(InstType.B){
      imm := bImm
    }
    is(InstType.JAL){
      imm := jImm
    }
    is(InstType.R){
      imm := rImm
    }
  }
  io.imm := imm
}
class QUIT extends BlackBox with HasBlackBoxInline {
  val io = IO(new Bundle{
    val is_quit = Input(Bool())
  })
  setInline("QUIT.sv",
    s"""
    module QUIT(
      input is_quit
    );
      import \"DPI-C\" function void quit();
      always_comb begin
        if(is_quit) quit();
      end
    endmodule
    """)
}
class IDU extends Module {
  val io = IO(new Bundle {
    val inst = Input(UInt(32.W))
    val instType = Output(InstType())
    val func = Output(UInt(3.W))
    val raddrIO = Flipped(new RegFileRaddrIO(2))
    val rd = Output(UInt(5.W))
    val imm = Output(UInt(32.W))
  })
  
  val op = io.inst(6, 0)
  val func = io.inst(14, 12)
  val rs1 = io.inst(19, 15)
  val rs2 = io.inst(24, 20)
  val rd = io.inst(11, 7)
  val instType = Decoder(io.inst)
  
  val immGen = Module(new ImmGen)
  immGen.io.inst := io.inst  // 传递指令
  immGen.io.instType := instType
  val imm = immGen.io.imm
  
  io.func := func
  io.raddrIO.raddr(0) := rs1
  io.raddrIO.raddr(1) := rs2
  io.rd := rd
  io.imm := imm
  io.instType := instType
  val quit = Module(new QUIT())
  quit.io.is_quit := io.inst === "h00100073".U
}
