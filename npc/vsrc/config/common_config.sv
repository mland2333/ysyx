
`define BRANCH_MID 7:0
`define BRANCH 0
`define BRANCH_BACK 1
`define BEQ 2
`define ZERO 3
`define BNE 4
`define BLT 5
`define CMP 6
`define BGE 7

`define CACHE_LINE_WIDTH 128
`define DCACHE_LINE_WIDTH 256

`define PREG_NUM 64

`define PREG_NUM_INDEX $clog2(`PREG_NUM)
`define REG_NUM_INDEX `PREG_NUM_INDEX

`define ROB_NUM 64
`define ROB_NUM_INDEX $clog2(`ROB_NUM)
