interface AXIFULL();
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
  modport master(
    input  awready,
    output awvalid,
    output awaddr,
    output awid,
    output awlen,
    output awsize,
    output awburst,
    input  wready,
    output wvalid,
    output wdata,
    output wstrb,
    output wlast,
    output bready,
    input  bvalid,
    input  bresp,
    input  bid,
    input  arready,
    output arvalid,
    output araddr,
    output arid,
    output arlen,
    output arsize,
    output arburst,
    output rready,
    input  rvalid,
    input  rresp,
    input  rdata,
    input  rlast,
    input  rid
  );
  modport slave(
    output awready,
    input  awvalid,
    input  awaddr,
    input  awid,
    input  awlen,
    input  awsize,
    input  awburst,
    output wready,
    input  wvalid,
    input  wdata,
    input  wstrb,
    input  wlast,
    input  bready,
    output bvalid,
    output bresp,
    output bid,
    output arready,
    input  arvalid,
    input  araddr,
    input  arid,
    input  arlen,
    input  arsize,
    input  arburst,
    input  rready,
    output rvalid,
    output rresp,
    output rdata,
    output rlast,
    output rid
  );
endinterface

interface AXIFULL_READ();
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
    input  arready,
    output arvalid,
    output araddr,
    output arid,
    output arlen,
    output arsize,
    output arburst,
    output rready,
    input  rvalid,
    input  rresp,
    input  rdata,
    input  rlast,
    input  rid
  );
  modport slave(
    output arready,
    input  arvalid,
    input  araddr,
    input  arid,
    input  arlen,
    input  arsize,
    input  arburst,
    input  rready,
    output rvalid,
    output rresp,
    output rdata,
    output rlast,
    output rid
  );
endinterface
interface AXIFULL_WRITE();
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
    input  awready,
    output awvalid,
    output awaddr,
    output awid,
    output awlen,
    output awsize,
    output awburst,
    input  wready,
    output wvalid,
    output wdata,
    output wstrb,
    output wlast,
    output bready,
    input  bvalid,
    input  bresp,
    input  bid
  );
  modport slave(
    output awready,
    input  awvalid,
    input  awaddr,
    input  awid,
    input  awlen,
    input  awsize,
    input  awburst,
    output wready,
    input  wvalid,
    input  wdata,
    input  wstrb,
    input  wlast,
    input  bready,
    output bvalid,
    output bresp,
    output bid
  );
endinterface
