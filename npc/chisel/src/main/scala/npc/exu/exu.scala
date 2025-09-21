package npc.exu

import chisel3._
import chisel3.util._

import npc.idu.DataIO
import npc.lsu.LsuIO
import npc.idu.InstType

class EXU extends Module{
    val io = IO(new Bundle{
        val instType = Input(InstType())
        val func = Input(UInt(3.W))
        val dataIO = new DataIO
        val aluIn = new AluInputIO
        val result = Output(UInt(32.W))
        val jump = Output(Bool())
        val upc = Output(UInt(32.W))
        val resultType = Output(UInt(1.W))
        val lsuIO = Flipped(new LsuIO)
        val regWen = Output(Bool())
    })
    val alu = Module(new ALU())
    alu.io.in := io.aluIn
    io.result := alu.io.out.result
    val cmp = alu.io.out.cmp
    val zero = io.dataIO.rs1 === io.dataIO.rs2
    val jump = io.instType === InstType.JAL | io.instType === InstType.JALR
    io.upc := Mux(io.instType === InstType.JALR, io.dataIO.rs1, io.dataIO.pc) + io.dataIO.imm
    io.regWen := ~(io.instType === InstType.S | io.instType === InstType.B)
    io.lsuIO.wen := io.instType === InstType.S
    io.lsuIO.ren := io.instType === InstType.L
    io.resultType := Mux(io.instType === InstType.L, 1.U, 0.U)
    val wmask = Wire(UInt(4.W))
        when (io.instType === InstType.S) {
            when (io.func === "b000".U)    { wmask := "b0001".U }
            .elsewhen (io.func === "b001".U) { wmask := "b0011".U }
            .otherwise                      { wmask := "b1111".U }
        }.otherwise {
        wmask := 0.U
    }
    io.lsuIO.wmask := wmask
    io.lsuIO.addr := alu.io.out.add_result
    io.lsuIO.wdata := io.dataIO.rs2
    io.lsuIO.read_type := io.func
    val is_beq = io.instType === InstType.B & io.func === "b000".U
    val is_bne = io.instType === InstType.B & io.func === "b001".U
    val is_blt = io.instType === InstType.B & (io.func === "b100".U | io.func === "b110".U)
    val is_bge = io.instType === InstType.B & (io.func === "b101".U | io.func === "b111".U)
    val branch = is_beq & zero | is_bne & ~zero | is_blt & cmp.asBool | is_bge & ~cmp.asBool
    io.jump := jump | branch
}
