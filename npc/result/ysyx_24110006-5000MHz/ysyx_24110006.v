//Generate the verilog at 2025-01-03T21:21:23
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
wire \a[0] ;
wire \a[1] ;
wire \a[2] ;
wire \a[3] ;
wire \a[4] ;
wire \a[5] ;
wire \a[6] ;
wire \a[7] ;
wire \a[8] ;
wire \a[9] ;
wire \a[10] ;
wire \a[11] ;
wire \a[12] ;
wire \a[13] ;
wire \a[14] ;
wire \a[15] ;
wire \a[16] ;
wire \a[17] ;
wire \a[18] ;
wire \a[19] ;
wire \a[20] ;
wire \a[21] ;
wire \a[22] ;
wire \a[23] ;
wire \a[24] ;
wire \a[25] ;
wire \a[26] ;
wire \a[27] ;
wire \a[28] ;
wire \a[29] ;
wire \a[30] ;
wire \a[31] ;
wire \b[0] ;
wire \b[1] ;
wire \b[2] ;
wire \b[3] ;
wire \b[4] ;
wire \b[5] ;
wire \b[6] ;
wire \b[7] ;
wire \b[8] ;
wire \b[9] ;
wire \b[10] ;
wire \b[11] ;
wire \b[12] ;
wire \b[13] ;
wire \b[14] ;
wire \b[15] ;
wire \b[16] ;
wire \b[17] ;
wire \b[18] ;
wire \b[19] ;
wire \b[20] ;
wire \b[21] ;
wire \b[22] ;
wire \b[23] ;
wire \b[24] ;
wire \b[25] ;
wire \b[26] ;
wire \b[27] ;
wire \b[28] ;
wire \b[29] ;
wire \b[30] ;
wire \b[31] ;
wire \r_b[0] ;

assign \a[0] = a[0] ;
assign \b[0] = b[0] ;

MUX2_X1 _22_ ( .A(_09_ ), .B(_00_ ), .S(_13_ ), .Z(_01_ ) );
XNOR2_X2 _23_ ( .A(_11_ ), .B(_09_ ), .ZN(_07_ ) );
XNOR2_X1 _24_ ( .A(_07_ ), .B(_10_ ), .ZN(_08_ ) );
MUX2_X2 _25_ ( .A(_12_ ), .B(_08_ ), .S(_13_ ), .Z(_02_ ) );
MUX2_X1 _26_ ( .A(_11_ ), .B(_06_ ), .S(_13_ ), .Z(_03_ ) );
MUX2_X1 _27_ ( .A(_10_ ), .B(_05_ ), .S(_13_ ), .Z(_04_ ) );
DFF_X1 _28_ ( .D(_18_ ), .CK(clock ), .Q(r_a ), .QN(_17_ ) );
DFF_X1 _29_ ( .D(_19_ ), .CK(clock ), .Q(result ), .QN(_16_ ) );
DFF_X1 _30_ ( .D(_20_ ), .CK(clock ), .Q(r_cin ), .QN(_15_ ) );
DFF_X1 _31_ ( .D(_21_ ), .CK(clock ), .Q(\r_b[0] ), .QN(_14_ ) );
BUF_X1 _32_ ( .A(r_cin ), .Z(_11_ ) );
BUF_X1 _33_ ( .A(r_a ), .Z(_09_ ) );
BUF_X1 _34_ ( .A(\r_b[0] ), .Z(_10_ ) );
BUF_X1 _35_ ( .A(\a[0] ), .Z(_00_ ) );
BUF_X1 _36_ ( .A(valid ), .Z(_13_ ) );
BUF_X1 _37_ ( .A(_01_ ), .Z(_18_ ) );
BUF_X1 _38_ ( .A(result ), .Z(_12_ ) );
BUF_X1 _39_ ( .A(_02_ ), .Z(_19_ ) );
BUF_X1 _40_ ( .A(cin ), .Z(_06_ ) );
BUF_X1 _41_ ( .A(_03_ ), .Z(_20_ ) );
BUF_X1 _42_ ( .A(\b[0] ), .Z(_05_ ) );
BUF_X1 _43_ ( .A(_04_ ), .Z(_21_ ) );

endmodule
