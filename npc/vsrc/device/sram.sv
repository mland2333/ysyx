`ifndef CONFIG_YSYXSOC
import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int  waddr,
  input int  wdata,
  input byte wmask
);

module ysyx_24110006_SRAM (
    input i_clock,
    input i_reset,
    if_axi.slave i_axi
);

  // AXI信号定义
  wire        arvalid = i_axi.arvalid;
  wire [31:0] araddr = i_axi.araddr;
  wire [ 2:0] arsize = i_axi.arsize;
  wire [ 7:0] arlen = i_axi.arlen;
  wire [ 1:0] arburst = i_axi.arburst;
  wire        rready = i_axi.rready;

  wire        awvalid = i_axi.awvalid;
  wire [31:0] awaddr = i_axi.awaddr;
  wire [ 2:0] awsize = i_axi.awsize;
  wire [ 7:0] awlen = i_axi.awlen;
  wire [ 1:0] awburst = i_axi.awburst;

  wire        wvalid = i_axi.wvalid;
  wire [31:0] wdata = i_axi.wdata;
  wire [ 3:0] wstrb = i_axi.wstrb;
  wire        wlast = i_axi.wlast;

  wire        bready = i_axi.bready;

  // 读通道状态机
  typedef enum logic [1:0] {
    R_IDLE,
    R_ADDR,
    R_DATA
  } read_state_t;

  read_state_t r_state, r_next_state;

  // 写通道状态机 - 修改为支持独立的地址和数据通道
  typedef enum logic [2:0] {
    W_IDLE,
    W_ADDR_ONLY,  // 只收到地址
    W_DATA_ONLY,  // 只收到数据
    W_BOTH,       // 地址和数据都收到
    W_RESP
  } write_state_t;

  write_state_t w_state, w_next_state;

  // 读通道寄存器
  reg [31:0] r_araddr;
  reg [ 2:0] r_arsize;
  reg [ 7:0] r_arlen;
  reg [ 1:0] r_arburst;
  reg [ 7:0] r_beat_cnt;
  reg [31:0] r_current_addr;

  // 写通道寄存器
  reg [31:0] w_awaddr;
  reg [ 2:0] w_awsize;
  reg [ 7:0] w_awlen;
  reg [ 1:0] w_awburst;
  reg [ 7:0] w_beat_cnt;
  reg [31:0] w_current_addr;

  // 写通道控制信号
  reg        w_addr_received;
  reg        w_data_received;
  reg        w_can_write;

  // 输出寄存器
  reg        arready_r;
  reg [31:0] rdata_r;
  reg        rvalid_r;
  reg        rlast_r;
  reg [ 1:0] rresp_r;

  reg        awready_r;
  reg        wready_r;
  reg        bvalid_r;
  reg [ 1:0] bresp_r;

  // 连接输出
  assign i_axi.arready = arready_r;
  assign i_axi.rdata   = rdata_r;
  assign i_axi.rvalid  = rvalid_r;
  assign i_axi.rlast   = rlast_r;
  assign i_axi.rresp   = rresp_r;

  assign i_axi.awready = awready_r;
  assign i_axi.wready  = wready_r;
  assign i_axi.bvalid  = bvalid_r;
  assign i_axi.bresp   = bresp_r;

  // 地址计算函数
  function automatic [31:0] next_addr(input [31:0] addr, input [2:0] size, input [1:0] burst);
    case (burst)
      2'b00:   next_addr = addr;  // FIXED
      2'b01: begin  // INCR
        case (size)
          3'b000:  next_addr = addr + 1;  // 1 byte
          3'b001:  next_addr = addr + 2;  // 2 bytes
          3'b010:  next_addr = addr + 4;  // 4 bytes
          default: next_addr = addr + 4;
        endcase
      end
      2'b10: begin  // WRAP
        // 简化实现，当作INCR处理
        case (size)
          3'b000:  next_addr = addr + 1;
          3'b001:  next_addr = addr + 2;
          3'b010:  next_addr = addr + 4;
          default: next_addr = addr + 4;
        endcase
      end
      default: next_addr = addr;
    endcase
  endfunction

  // 读通道状态机
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      r_state <= R_IDLE;
    end else begin
      r_state <= r_next_state;
    end
  end

  always_comb begin
    r_next_state = r_state;
    unique case (r_state)
      R_IDLE: begin
        if (arvalid) begin
          r_next_state = R_ADDR;
        end
      end
      R_ADDR: begin
        r_next_state = R_DATA;
      end
      R_DATA: begin
        if (rvalid_r && rready && rlast_r) begin
          r_next_state = R_IDLE;
        end
      end
    endcase
  end

  // 读地址通道
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      arready_r <= 1'b0;
      r_araddr <= 32'b0;
      r_arsize <= 3'b0;
      r_arlen <= 8'b0;
      r_arburst <= 2'b0;
      r_current_addr <= 32'b0;
    end else begin
      unique case (r_state)
        R_IDLE: begin
          arready_r <= 1'b1;
          if (arvalid && arready_r) begin
            r_araddr <= araddr;
            r_arsize <= arsize;
            r_arlen <= arlen;
            r_arburst <= arburst;
            r_current_addr <= araddr;
            arready_r <= 1'b0;
          end
        end
        R_ADDR: begin
          arready_r <= 1'b0;
        end
        R_DATA: begin
          arready_r <= 1'b0;
          if (rvalid_r && rready && !rlast_r) begin
            r_current_addr <= next_addr(r_current_addr, r_arsize, r_arburst);
          end
        end
      endcase
    end
  end

  // 读数据通道
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      rvalid_r <= 1'b0;
      rdata_r <= 32'b0;
      rlast_r <= 1'b0;
      rresp_r <= 2'b00;
      r_beat_cnt <= 8'b0;
    end else begin
      unique case (r_state)
        R_IDLE: begin
          rvalid_r <= 1'b0;
          rlast_r <= 1'b0;
          r_beat_cnt <= 8'b0;
        end
        R_ADDR: begin
          // 开始第一次读取
          rdata_r <= pmem_read(r_current_addr);
          rvalid_r <= 1'b1;
          rlast_r <= (r_arlen == 8'b0);
          rresp_r <= 2'b00;  // OKAY
          r_beat_cnt <= 8'b0;
        end
        R_DATA: begin
          if (rvalid_r && rready) begin
            if (rlast_r) begin
              rvalid_r <= 1'b0;
              rlast_r  <= 1'b0;
            end else begin
              // 准备下一个数据
              r_beat_cnt <= r_beat_cnt + 1;
              rdata_r <= pmem_read(next_addr(r_current_addr, r_arsize, r_arburst));
              rlast_r <= (r_beat_cnt + 1 == r_arlen);
            end
          end
        end
      endcase
    end
  end

  // 写通道状态机 - 支持地址和数据的任意顺序
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      w_state <= W_IDLE;
    end else begin
      w_state <= w_next_state;
    end
  end

  always_comb begin
    w_next_state = w_state;
    unique case (w_state)
      W_IDLE: begin
        if (awvalid && wvalid) begin
          // 地址和数据同时到达
          w_next_state = W_BOTH;
        end else if (awvalid) begin
          // 只有地址到达
          w_next_state = W_ADDR_ONLY;
        end else if (wvalid) begin
          // 只有数据到达
          w_next_state = W_DATA_ONLY;
        end
      end
      W_ADDR_ONLY: begin
        if (wvalid) begin
          // 数据到达，可以开始写入
          w_next_state = W_BOTH;
        end
      end
      W_DATA_ONLY: begin
        if (awvalid) begin
          // 地址到达，可以开始写入
          w_next_state = W_BOTH;
        end
      end
      W_BOTH: begin
        if (w_can_write && wlast) begin
          w_next_state = W_RESP;
        end
      end
      W_RESP: begin
        if (bvalid_r && bready) begin
          w_next_state = W_IDLE;
        end
      end
    endcase
  end

  // 写地址通道 - 独立处理
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      awready_r <= 1'b1;  // 始终准备接收地址
      w_awaddr <= 32'b0;
      w_awsize <= 3'b0;
      w_awlen <= 8'b0;
      w_awburst <= 2'b0;
      w_current_addr <= 32'b0;
      w_addr_received <= 1'b0;
    end else begin
      // 地址通道独立处理
      if (awvalid && awready_r && !w_addr_received) begin
        w_awaddr <= awaddr;
        w_awsize <= awsize;
        w_awlen <= awlen;
        w_awburst <= awburst;
        w_current_addr <= awaddr;
        w_addr_received <= 1'b1;
        awready_r <= 1'b0;  // 一次事务只接收一次地址
      end

      // 事务完成后重置
      if (w_state == W_RESP && bvalid_r && bready) begin
        w_addr_received <= 1'b0;
        awready_r <= 1'b1;
      end
    end
  end

  // 写数据通道 - 独立处理
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      wready_r <= 1'b0;
      w_beat_cnt <= 8'b0;
      w_data_received <= 1'b0;
      w_can_write <= 1'b0;
    end else begin
      // 只有当地址和数据都准备好时才能写入
      w_can_write <= w_addr_received && (w_state == W_BOTH || w_state == W_DATA_ONLY);

      unique case (w_state)
        W_IDLE: begin
          wready_r <= 1'b1;  // 准备接收数据
          w_beat_cnt <= 8'b0;
          w_data_received <= 1'b0;
        end
        W_ADDR_ONLY: begin
          wready_r <= 1'b1;  // 等待数据
        end
        W_DATA_ONLY: begin
          wready_r <= 1'b0;  // 等待地址，暂停接收数据
        end
        W_BOTH: begin
          wready_r <= 1'b1;  // 可以接收数据
          if (w_can_write) begin
            // 执行写操作
            pmem_write(w_current_addr, wdata, {4'b0, wstrb});

            if (wlast) begin
              wready_r <= 1'b0;
              w_data_received <= 1'b1;
            end else begin
              w_beat_cnt <= w_beat_cnt + 1;
              w_current_addr <= next_addr(w_current_addr, w_awsize, w_awburst);
            end
          end
        end
        W_RESP: begin
          wready_r <= 1'b0;
        end
      endcase
    end
  end

  // 写响应通道
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      bvalid_r <= 1'b0;
      bresp_r  <= 2'b00;
    end else begin
      unique case (w_state)
        W_BOTH: begin
          if (wlast && w_can_write) begin
            bvalid_r <= 1'b1;
            bresp_r  <= 2'b00;  // OKAY
          end
        end
        W_RESP: begin
          if (bvalid_r && bready) begin
            bvalid_r <= 1'b0;
          end
        end
        default: begin
          if (w_state == W_IDLE) begin
            bvalid_r <= 1'b0;
          end
        end
      endcase
    end
  end

  /* // 性能监控 */
  /* always_ff @(posedge i_clock) begin */
  /*     if (!i_reset) begin */
  /*         // 每个时钟周期计数 */
  /*         $c("perf_trigger_event_by_name(\"EVENT_CYCLE\");"); */
  /**/
  /*         // 读操作完成时触发指令提交事件 */
  /*         if (rvalid_r && rready && rlast_r) begin */
  /*             $c("perf_trigger_event_by_name(\"EVENT_INST_COMMIT\");"); */
  /*         end */
  /**/
  /*         // 写操作完成时也触发指令提交事件 */
  /*         if (w_state == W_BOTH && wvalid && wready_r && wlast && w_can_write) begin */
  /*             $c("perf_trigger_event_by_name(\"EVENT_INST_COMMIT\");"); */
  /*         end */
  /*     end */
  /* end */

endmodule
`endif
