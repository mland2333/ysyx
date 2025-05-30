`ifndef CONFIG_YSYXSOC
module ysyx_24110006_UART (
    input i_clock,
    input i_reset,
    if_axi_write.slave i_axi_w
);

  // 写通道状态机
  typedef enum logic [2:0] {
    W_IDLE,
    W_ADDR_ONLY,  // 只收到地址
    W_DATA_ONLY,  // 只收到数据
    W_BOTH,       // 地址和数据都收到
    W_RESP
  } write_state_t;

  write_state_t w_state, w_next_state;

  // 写通道寄存器
  reg  [31:0] w_awaddr;
  reg  [ 3:0] w_awid;
  reg  [ 7:0] w_awlen;
  reg  [ 2:0] w_awsize;
  reg  [ 1:0] w_awburst;
  reg  [31:0] w_wdata;
  reg  [ 3:0] w_wstrb;
  reg  [ 7:0] w_beat_cnt;

  // 写通道控制信号
  reg         w_addr_received;
  reg         w_data_received;
  reg         w_can_write;

  // 输出寄存器
  reg         awready_r;
  reg         wready_r;
  reg         bvalid_r;
  reg  [ 1:0] bresp_r;
  reg  [ 3:0] bid_r;

  // AXI信号连接
  wire        awvalid = i_axi_w.awvalid;
  wire [31:0] awaddr = i_axi_w.awaddr;
  wire [ 3:0] awid = i_axi_w.awid;
  wire [ 7:0] awlen = i_axi_w.awlen;
  wire [ 2:0] awsize = i_axi_w.awsize;
  wire [ 1:0] awburst = i_axi_w.awburst;

  wire        wvalid = i_axi_w.wvalid;
  wire [31:0] wdata = i_axi_w.wdata;
  wire [ 3:0] wstrb = i_axi_w.wstrb;
  wire        wlast = i_axi_w.wlast;

  wire        bready = i_axi_w.bready;

  // 连接输出
  assign i_axi_w.awready = awready_r;
  assign i_axi_w.wready  = wready_r;
  assign i_axi_w.bvalid  = bvalid_r;
  assign i_axi_w.bresp   = bresp_r;
  assign i_axi_w.bid     = bid_r;

  // 写通道状态机
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
      w_awid <= 4'b0;
      w_awlen <= 8'b0;
      w_awsize <= 3'b0;
      w_awburst <= 2'b0;
      w_addr_received <= 1'b0;
    end else begin
      // 地址通道独立处理
      if (awvalid && awready_r && !w_addr_received) begin
        w_awaddr <= awaddr;
        w_awid <= awid;
        w_awlen <= awlen;
        w_awsize <= awsize;
        w_awburst <= awburst;
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
      w_wdata <= 32'b0;
      w_wstrb <= 4'b0;
      w_beat_cnt <= 8'b0;
      w_data_received <= 1'b0;
      w_can_write <= 1'b0;
    end else begin
      // 只有当地址和数据都准备好时才能写入
      w_can_write <= w_addr_received && (w_state == W_BOTH);

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
            // 保存写数据
            w_wdata <= wdata;
            w_wstrb <= wstrb;

            // UART写操作 - 输出字符
            /* if (w_awaddr[7:0] == 8'h00) begin  // UART数据寄存器 */
              $write("%c", wdata[7:0]);
            /* end */

            if (wlast) begin
              wready_r <= 1'b0;
              w_data_received <= 1'b1;
            end else begin
              w_beat_cnt <= w_beat_cnt + 1;
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
      bresp_r <= 2'b00;
      bid_r <= 4'b0;
    end else begin
      case (w_state)
        W_BOTH: begin
          if (wlast && w_can_write) begin
            bvalid_r <= 1'b1;
            bresp_r <= 2'b00;  // OKAY
            bid_r <= w_awid;  // 返回对应的ID
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

  // 性能监控
  /* always_ff @(posedge i_clock) begin */
  /*     if (!i_reset) begin */
  /*         // 每个时钟周期计数 */
  /*         $c("perf_trigger_event_by_name(\"EVENT_CYCLE\");"); */
  /**/
  /*         // 写操作完成时触发指令提交事件 */
  /*         if (w_state == W_BOTH && wvalid && wready_r && wlast && w_can_write) begin */
  /*             $c("perf_trigger_event_by_name(\"EVENT_INST_COMMIT\");"); */
  /*         end */
  /*     end */
  /* end */

endmodule

`endif
