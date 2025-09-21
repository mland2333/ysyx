package npc.reg

import chisel3._
import chisel3.util._
import chisel3.Bundle
class RegFileRaddrIO(read_ports:Int) extends Bundle{
    val raddr = Input(Vec(read_ports, UInt(5.W)))
}
class RegFileRdataIO(read_ports:Int) extends Bundle{
    val rdata = Output(Vec(read_ports, UInt(32.W)))
}
class RegFileWriteIO(write_ports:Int) extends Bundle{
    val wen = Input(Vec(write_ports, Bool()))
    val wd = Input(Vec(write_ports, UInt(5.W)))
    val wdata = Input(Vec(write_ports, UInt(32.W)))
}
class RegFile(read_ports:Int, write_ports:Int) extends Module{
    require(read_ports >= 0)
    require(write_ports >= 0)
    val io = IO(new Bundle{
        val raddrIO = new RegFileRaddrIO(read_ports)
        val rdataIO = new RegFileRdataIO(read_ports)
        val wIO = new RegFileWriteIO(write_ports)
    })
    val regs = Reg(Vec(32, UInt(32.W)))
    for(i <- 0.until(write_ports)){
        when(io.wIO.wen(i)){
            regs(io.wIO.wd(i)) := io.wIO.wdata(i)
        }
    }
    for(i <- 0.until(read_ports)){
        when (io.raddrIO.raddr(i) === 0.U){
            io.rdataIO.rdata(i) := 0.U
        }.otherwise{
            io.rdataIO.rdata(i) := regs(io.raddrIO.raddr(i))
        }
    }
}