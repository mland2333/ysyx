//Generate the verilog at 2025-01-03T21:20:17
module ysyx_24110006 (
clock,
reset,
result,
valid,
a,
b
);

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
wire clock ;
wire r_a ;
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

MUX2_X1 _16_ ( .A(_06_ ), .B(_00_ ), .S(_09_ ), .Z(_01_ ) );
XNOR2_X2 _17_ ( .A(_07_ ), .B(_06_ ), .ZN(_05_ ) );
MUX2_X2 _18_ ( .A(_08_ ), .B(_05_ ), .S(_09_ ), .Z(_02_ ) );
MUX2_X1 _19_ ( .A(_07_ ), .B(_04_ ), .S(_09_ ), .Z(_03_ ) );
DFF_X1 _20_ ( .D(_13_ ), .CK(clock ), .Q(r_a ), .QN(_12_ ) );
DFF_X1 _21_ ( .D(_14_ ), .CK(clock ), .Q(result ), .QN(_11_ ) );
DFF_X1 _22_ ( .D(_15_ ), .CK(clock ), .Q(\r_b[0] ), .QN(_10_ ) );
BUF_X1 _23_ ( .A(\r_b[0] ), .Z(_07_ ) );
BUF_X1 _24_ ( .A(r_a ), .Z(_06_ ) );
BUF_X1 _25_ ( .A(\a[0] ), .Z(_00_ ) );
BUF_X1 _26_ ( .A(valid ), .Z(_09_ ) );
BUF_X1 _27_ ( .A(_01_ ), .Z(_13_ ) );
BUF_X1 _28_ ( .A(result ), .Z(_08_ ) );
BUF_X1 _29_ ( .A(_02_ ), .Z(_14_ ) );
BUF_X1 _30_ ( .A(\b[0] ), .Z(_04_ ) );
BUF_X1 _31_ ( .A(_03_ ), .Z(_15_ ) );

endmodule
