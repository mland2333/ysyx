interface if_fencei ();
  logic rq;
  logic fin;
  modport master(output rq, input fin);
  modport slave(input rq, output fin);
endinterface
