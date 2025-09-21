package npc.exu

import chisel3._
import chisel3.util._

object AluType extends ChiselEnum {
  val ALU_ADD, ALU_SLL, ALU_SLT, ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND = Value
}

class AluInputIO extends Bundle {
  val a = Input(UInt(32.W))
  val b = Input(UInt(32.W))
  val sub = Input(Bool())
  val sign = Input(Bool())
  val aluType = Input(AluType())
}

class AluOutputIO extends Bundle {
  val result = Output(UInt(32.W))
  val add_result = Output(UInt(32.W))
  val cmp = Output(UInt(1.W))
}

class AluIO extends Bundle {
  val in = new AluInputIO
  val out = new AluOutputIO
}

class ALU extends Module {
  val io = IO(new AluIO)
  
  val cout = WireDefault(false.B)
  val sum = WireDefault(0.U(33.W))
  sum := io.in.a +& io.in.b + io.in.sub.asUInt
  io.out.add_result := sum(31, 0)
  cout := sum(32)
  val add = sum(31, 0)
  val sll = io.in.a << io.in.b(4, 0)
  val slt = Cat(Fill(31, io.in.a(31)), io.out.cmp)
  val xor = io.in.a ^ io.in.b
  val srl = io.in.a >> io.in.b(4, 0)
  val sra = (io.in.a.asSInt >> io.in.b(4, 0)).asUInt
  val or = io.in.a | io.in.b
  val and = io.in.a & io.in.b
  
  val result = WireDefault(0.U(32.W))
  switch(io.in.aluType) {
    is(AluType.ALU_ADD) { result := add }
    is(AluType.ALU_SLL) { result := sll }
    is(AluType.ALU_SLT) { result := slt }
    is(AluType.ALU_XOR) { result := xor }
    is(AluType.ALU_SRL) { result := srl }
    is(AluType.ALU_SRA) { result := sra }
    is(AluType.ALU_OR) { result := or }
    is(AluType.ALU_AND) { result := and }
  }
  
  io.out.cmp := Mux(io.in.sign, io.in.a(31) & io.in.b(31) | add(31) & (io.in.a(31) ^ io.in.b(31)), ~cout)
  io.out.result := result
}