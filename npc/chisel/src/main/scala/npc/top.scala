package npc

import chisel3._
import chisel3.util._
import _root_.circt.stage.ChiselStage
import npc.ifu.IFU
import npc.idu.IDU
import npc.idu.OpSel
import npc.exu.EXU
import npc.lsu.LSU
import npc.reg.RegFile
import npc.idu.DataIO

class top extends Module{
    val io = IO(new Bundle{

    })
    val ifu = Module(new IFU(reset_vector = BigInt("80000000", 16).U(32.W)))
    val idu = Module(new IDU())
    val opSel = Module(new OpSel())
    val exu = Module(new EXU())
    val lsu = Module(new LSU())
    val regfile = Module(new RegFile(read_ports = 2, write_ports = 1))
    ifu.io.upc := exu.io.upc
    ifu.io.jump := exu.io.jump
    idu.io.inst := ifu.io.inst
    regfile.io.raddrIO := idu.io.raddrIO
    regfile.io.wIO.wen(0) := exu.io.regWen
    regfile.io.wIO.wd(0) := idu.io.rd
    val reg_wdata = Wire(UInt(32.W))
    reg_wdata := Mux(exu.io.resultType === 0.U, exu.io.result, lsu.io.rdata)
    regfile.io.wIO.wdata(0) := reg_wdata
    val dataIO = Wire(new DataIO)
    dataIO.rs1 := regfile.io.rdataIO.rdata(0)
    dataIO.rs2 := regfile.io.rdataIO.rdata(1)
    dataIO.imm := idu.io.imm
    dataIO.pc := ifu.io.pc
    opSel.io.dataIO := dataIO
    opSel.io.instType := idu.io.instType
    opSel.io.func := idu.io.func

    exu.io.instType := idu.io.instType
    exu.io.func := idu.io.func
    exu.io.aluIn := opSel.io.aluIO
    exu.io.dataIO := dataIO

    lsu.io.lsuIO := exu.io.lsuIO
}
object Top extends App {
  ChiselStage.emitSystemVerilogFile(
    new top,
    args = Array("--target-dir", "../vsrc"),
    firtoolOpts = Array("-disable-all-randomization", "-strip-debug-info", "-default-layer-specialization=enable")
  )
}
