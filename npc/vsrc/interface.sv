interface if_axi();
  logic        awready;
  logic        awvalid;
  logic [31:0] awaddr;
  logic [3:0]  awid;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic        wready;
  logic        wvalid;
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  logic        bready;
  logic        bvalid;
  logic [1:0]  bresp;
  logic [3:0]  bid;
  logic        arready;
  logic        arvalid;
  logic [31:0] araddr;
  logic [3:0]  arid;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        rready;
  logic        rvalid;
  logic [1:0]  rresp;
  logic [31:0] rdata;
  logic        rlast;
  logic [3:0]  rid;
  modport master (
    output awvalid, awaddr, awid, awlen, awsize, awburst,
    input  awready,
    output wvalid, wdata, wstrb, wlast,
    input  wready,
    output bready,
    input  bvalid, bresp, bid,
    output arvalid, araddr, arid, arlen, arsize, arburst,
    input  arready,
    output rready,
    input  rvalid, rresp, rdata, rlast, rid
    );
  modport slave (
    input awvalid, awaddr, awid, awlen, awsize, awburst,
    output  awready,
    input wvalid, wdata, wstrb, wlast,
    output  wready,
    input bready,
    output  bvalid, bresp, bid,
    input arvalid, araddr, arid, arlen, arsize, arburst,
    output  arready,
    input rready,
    output  rvalid, rresp, rdata, rlast, rid
    );
endinterface

interface if_axi_read();
  logic        arready;
  logic        arvalid;
  logic [31:0] araddr;
  logic [3:0]  arid;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        rready;
  logic        rvalid;
  logic [1:0]  rresp;
  logic [31:0] rdata;
  logic        rlast;
  logic [3:0]  rid;
  modport master(
    output arvalid, araddr, arid, arlen, arsize, arburst,
    input  arready,
    output rready,
    input  rvalid, rresp, rdata, rlast, rid
  );
  modport slave(
    input arvalid, araddr, arid, arlen, arsize, arburst,
    output  arready,
    input rready,
    output  rvalid, rresp, rdata, rlast, rid
  );
endinterface
interface if_axi_write();
  logic        awready;
  logic        awvalid;
  logic [31:0] awaddr;
  logic [3:0]  awid;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic        wready;
  logic        wvalid;
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  logic        bready;
  logic        bvalid;
  logic [1:0]  bresp;
  logic [3:0]  bid;
  modport master(
    output awvalid, awaddr, awid, awlen, awsize, awburst,
    input  awready,
    output wvalid, wdata, wstrb, wlast,
    input  wready,
    output bready,
    input  bvalid, bresp, bid
  );
  modport slave(
    input awvalid, awaddr, awid, awlen, awsize, awburst,
    output  awready,
    input wvalid, wdata, wstrb, wlast,
    output  wready,
    input bready,
    output  bvalid, bresp, bid
  );
endinterface

interface if_pipeline_vr();
  logic valid;
  logic ready;
  modport in(
    input valid,
    output ready
  );
  modport out(
    output valid,
    input ready
  );
endinterface


