package mstd;

  class vector #(
      type T = int
  );
    T data[];
    int size;
    int capacity;
    function new();
      size = 0;
      capacity = 1;
      data = new[1];
    endfunction
    function automatic void push_back(ref T d);
      if (size == capacity) begin
        capacity = capacity * 2;
        data = new[capacity] (data);
      end
      data[size] = d;
      size++;
    endfunction
  endclass


endpackage
