//Generate the verilog at 2025-01-03T21:21:22
module ysyx_24110006 (
cin,
clock,
reset,
result,
valid,
a,
b
);

input cin ;
input clock ;
input reset ;
output result ;
input valid ;
input [31:0] a ;
input [31:0] b ;

wire _00_ ;
wire _01_ ;
wire _02_ ;
wire _03_ ;
wire _04_ ;
wire _05_ ;
wire _06_ ;
wire _07_ ;
wire _08_ ;
wire _09_ ;
wire _10_ ;
wire _11_ ;
wire _12_ ;
wire _13_ ;
wire _14_ ;
wire _15_ ;
wire _16_ ;
wire _17_ ;
wire _18_ ;
wire _19_ ;
wire _20_ ;
wire _21_ ;
wire cin ;
wire clock ;
wire r_a ;
wire r_cin ;
wire reset ;
wire result ;
wire valid ;
wire [31:0] a ;
wire [31:0] b ;
wire [0:0] r_b ;


MUX2_X1 _22_ ( .A(_09_ ), .B(_00_ ), .S(_13_ ), .Z(_01_ ) );
XNOR2_X2 _23_ ( .A(_11_ ), .B(_09_ ), .ZN(_07_ ) );
XNOR2_X1 _24_ ( .A(_07_ ), .B(_10_ ), .ZN(_08_ ) );
MUX2_X2 _25_ ( .A(_12_ ), .B(_08_ ), .S(_13_ ), .Z(_02_ ) );
MUX2_X1 _26_ ( .A(_11_ ), .B(_06_ ), .S(_13_ ), .Z(_03_ ) );
MUX2_X1 _27_ ( .A(_10_ ), .B(_05_ ), .S(_13_ ), .Z(_04_ ) );
DFF_X1 _28_ ( .D(_18_ ), .CK(clock ), .Q(r_a ), .QN(_17_ ) );
DFF_X1 _29_ ( .D(_19_ ), .CK(clock ), .Q(result ), .QN(_16_ ) );
DFF_X1 _30_ ( .D(_20_ ), .CK(clock ), .Q(r_cin ), .QN(_15_ ) );
DFF_X1 _31_ ( .D(_21_ ), .CK(clock ), .Q(\r_b [0] ), .QN(_14_ ) );
BUF_X1 _32_ ( .A(r_cin ), .Z(_11_ ) );
BUF_X1 _33_ ( .A(r_a ), .Z(_09_ ) );
BUF_X1 _34_ ( .A(\r_b [0] ), .Z(_10_ ) );
BUF_X1 _35_ ( .A(\a [0] ), .Z(_00_ ) );
BUF_X1 _36_ ( .A(valid ), .Z(_13_ ) );
BUF_X1 _37_ ( .A(_01_ ), .Z(_18_ ) );
BUF_X1 _38_ ( .A(result ), .Z(_12_ ) );
BUF_X1 _39_ ( .A(_02_ ), .Z(_19_ ) );
BUF_X1 _40_ ( .A(cin ), .Z(_06_ ) );
BUF_X1 _41_ ( .A(_03_ ), .Z(_20_ ) );
BUF_X1 _42_ ( .A(\b [0] ), .Z(_05_ ) );
BUF_X1 _43_ ( .A(_04_ ), .Z(_21_ ) );

endmodule
