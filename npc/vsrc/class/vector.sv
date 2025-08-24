class Vector #(type T=logic);
  protected T data[];

  function new(int init_size=0);
    if (init_size > 0) data = new[init_size];
  endfunction

  function void push_back(T value);
    data.push_back(value);
  endfunction

  function T get(int idx);
    return data[idx];
  endfunction

  function int size();
    return data.size();
  endfunction
endclass

