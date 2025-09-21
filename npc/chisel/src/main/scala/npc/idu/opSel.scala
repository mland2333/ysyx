package npc.idu

import chisel3._
import chisel3.util._
import npc.idu.InstType
import npc.exu.AluInputIO
import npc.exu.AluType

class DataIO extends Bundle {
  val pc = Input(UInt(32.W))
  val rs1 = Input(UInt(32.W))
  val rs2 = Input(UInt(32.W))
  val imm = Input(UInt(32.W))
}

class OpSel extends Module {
  val io = IO(new Bundle {
    val instType = Input(InstType())
    val func = Input(UInt(3.W))
    val dataIO = new DataIO
    val aluIO = Flipped(new AluInputIO)
  })
  
  val f000 = io.func === "b000".U
  val f001 = io.func === "b001".U
  val f010 = io.func === "b010".U
  val f011 = io.func === "b011".U
  val f100 = io.func === "b100".U
  val f101 = io.func === "b101".U
  val f110 = io.func === "b110".U
  val f111 = io.func === "b111".U
  
  // ALU operand A selection
  val a = WireDefault(io.dataIO.rs1)
  switch(io.instType) {
    is(InstType.LUI) { a := 0.U(32.W) }
    is(InstType.JAL) { a := io.dataIO.pc }
    is(InstType.JALR) { a := io.dataIO.pc }
    is(InstType.AUIPC) { a := io.dataIO.pc }
  }
  io.aluIO.a := a
  
  // ALU operand B selection
  val b = WireDefault(io.dataIO.rs2)
  switch(io.instType) {
    is(InstType.I) { b := io.dataIO.imm }
    is(InstType.L) { b := io.dataIO.imm }
    is(InstType.S) { b := io.dataIO.imm }
    is(InstType.LUI) { b := io.dataIO.imm }
    is(InstType.AUIPC) { b := io.dataIO.imm }
    is(InstType.JAL) { b := 4.U }
    is(InstType.JALR) { b := 4.U }
  }
  
  // Subtraction selection
  val sub_sel = WireDefault(false.B)
  switch(io.instType) {
    is(InstType.R) {
      when(f010 || f011 || (f000 && io.dataIO.imm(5))) {
        sub_sel := true.B
      }
    }
    is(InstType.I) {
      when(f010 || f011) {
        sub_sel := true.B
      }
    }
    is(InstType.B) {
      sub_sel := true.B
    }
  }
  
  io.aluIO.b := Mux(sub_sel, ~b, b)
  io.aluIO.sub := sub_sel
  
  // Sign selection
  val sign = WireDefault(false.B)
  switch(io.instType) {
    is(InstType.R) {
      when(f010) {
        sign := true.B
      }
    }
    is(InstType.B) {
      when(f100 || f101) {
        sign := true.B
      }
    }
  }
  io.aluIO.sign := sign
  
  // ALU type selection
  val aluType = WireDefault(AluType.ALU_ADD)
  switch(io.instType) {
    is(InstType.R) {
      when(f000) { aluType := AluType.ALU_ADD }
      when(f001) { aluType := AluType.ALU_SLL }
      when(f010 || f011) { aluType := AluType.ALU_SLT }
      when(f100) { aluType := AluType.ALU_XOR }
      when(f101) {
        when(io.dataIO.imm(5)) {
          aluType := AluType.ALU_SRA
        }.otherwise {
          aluType := AluType.ALU_SRL
        }
      }
      when(f110) { aluType := AluType.ALU_OR }
      when(f111) { aluType := AluType.ALU_AND }
    }
    is(InstType.I) {
      when(f000) { aluType := AluType.ALU_ADD }
      when(f001) { aluType := AluType.ALU_SLL }
      when(f010 || f011) { aluType := AluType.ALU_SLT }
      when(f100) { aluType := AluType.ALU_XOR }
      when(f101) {
        when(io.dataIO.imm(10)) {
          aluType := AluType.ALU_SRA
        }.otherwise {
          aluType := AluType.ALU_SRL
        }
      }
      when(f110) { aluType := AluType.ALU_OR }
      when(f111) { aluType := AluType.ALU_AND }
    }
    is(InstType.S) { aluType := AluType.ALU_ADD }
    is(InstType.B) { aluType := AluType.ALU_ADD }
    is(InstType.U) { aluType := AluType.ALU_ADD }
    is(InstType.L) { aluType := AluType.ALU_ADD }
    is(InstType.LUI) { aluType := AluType.ALU_ADD }
    is(InstType.AUIPC) { aluType := AluType.ALU_ADD }
    is(InstType.JAL) { aluType := AluType.ALU_ADD }
    is(InstType.JALR) { aluType := AluType.ALU_ADD }
  }
  io.aluIO.aluType := aluType
}