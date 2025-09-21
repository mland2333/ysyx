//| mill-version: 1.0.5
import mill._
import mill.scalalib._
// Note: This project requires .mill-jvm-opts file containing:
//   -Dchisel.project.root=${PWD}
// This is needed because Chisel needs to know the project root directory
// to properly generate and handle test directories and output files.
// See: https://github.com/com-lihaoyi/mill/issues/3840

object npc extends ScalaModule { m =>
  def moduleDir = super.moduleDir / os.up
  def scalaVersion = "2.13.16"
  def scalacOptions = Seq(
    "-language:reflectiveCalls",
    "-deprecation",
    "-feature",
    "-Xcheckinit",
    "-Ymacro-annotations",
  )
  def mvnDeps = Seq(
    mvn"org.chipsalliance::chisel:7.0.0-RC1",
  )
  def scalacPluginMvnDeps = Seq(
    mvn"org.chipsalliance:::chisel-plugin:7.0.0-RC1",
  )
  def mainClass: T[Option[String]] = Some("npc.Top")
}
