module select_older_age #(
    parameter type T,
    parameter type C
) (
    input  T a,
    b,
    output  T select
);
  function automatic logic compare(input C a, input C b);
    return ~((a[$left(a)] == b[$left(a)]) ^ (a[$left(a)-1:0] < b[$left(a)-1:0]));
  endfunction
  function automatic T select_inner(input T a, input T b);
    if (a.valid && !b.valid) return a;
    else if (!a.valid && b.valid) return b;
    else if (!a.valid && !b.valid) return 0;
    else begin
      if (compare(a.age, b.age)) return a;
      else return b;
    end
  endfunction
  assign select = select_inner(a, b);

endmodule
module select_younger_age #(
    parameter type T,
    parameter type C
) (
    input  T a,
    b,
    output  T select
);
  function automatic logic compare(input C a, input C b);
    return ~((a[$left(a)] == b[$left(a)]) ^ (a[$left(a)-1:0] < b[$left(a)-1:0]));
  endfunction
  function automatic T select_inner(input T a, input T b);
    if (a.valid && !b.valid) return a;
    else if (!a.valid && b.valid) return b;
    else if (!a.valid && !b.valid) return 0;
    else begin
      if (!compare(a.age, b.age)) return a;
      else return b;
    end
  endfunction
  assign select = select_inner(a, b);

endmodule
