#include <perf.h>

void Perf::trace(Simulator* sim){
  if(timer_begin == 0) timer_begin = Utils::get_time();
  clk_nums ++;
  if(sim->TOP_MEMBER(pc_valid)) {
    if(clk_prev != 0){
      inst_clk[inst_type] += clk_nums - clk_prev;
    }
    clk_prev = clk_nums;
  }
  if(sim->TOP_MEMBER(ifu_valid)){
    inst_nums++;
    ifu_get_inst++;
    ifu_clk += clk_nums - clk_prev;
    idu_decode_inst(sim->get_inst());
  }
  if(sim->TOP_MEMBER(exu_valid)) {
    exu_finish_cal++;
    lsu_begin = clk_nums;
  }
  if(sim->TOP_MEMBER(mlsu__DOT__rvalid)) lsu_get_data++;
  if(sim->TOP_MEMBER(lsu_valid) && (sim->TOP_MEMBER(mlsu__DOT__wen) || sim->TOP_MEMBER(mlsu__DOT__ren)))
     lsu_clk += clk_nums - lsu_begin;
#ifdef CONFIG_ICACHE
  if(sim->TOP_MEMBER(mifu__DOT__micache__DOT__hit_counter)) hit_counter++;
  if(sim->TOP_MEMBER(mifu__DOT__micache__DOT__miss_counter)) miss_counter++;
  if(sim->TOP_MEMBER(mifu__DOT__micache__DOT__rlast)) miss_time += sim->TOP_MEMBER(mifu__DOT__micache__DOT__miss_time);
#endif
  }
void Perf::statistic(){
    uint64_t timer_end = Utils::get_time();
    Log("host time spent = %lu us", timer);
    Log("total host clk = %lu", clk_nums);
    Log("total host instructions = %lu", inst_nums);
    Log("指令速度：%.2f/s", (double)inst_nums / ((double)(timer_end - timer_begin)/ 1000000));
    Log("周期速度：%.2f/s", (double)clk_nums / ((double)(timer_end - timer_begin) / 1000000));
    Log("npc's ipc = %.6f", get_ipc());
    Log("ifu_get_inst = %lu", ifu_get_inst);
    Log("lsu_get_data = %lu", lsu_get_data);
    Log("exu_finish_cal = %lu", exu_finish_cal);
    Log("load 指令数量:%lu，占比 %.4f%%，平均执行周期数 %.2f", insts[LOAD], (double)insts[LOAD] / (double)inst_nums * 100, (double)inst_clk[LOAD] / (double)insts[LOAD]);
    Log("store 指令数量:%lu，占比 %.4f%%，平均执行周期数 %.2f", insts[STORE], (double)insts[STORE] / (double)inst_nums * 100, (double)inst_clk[STORE] / (double)insts[STORE]);
    Log("csr 指令数量:%lu，占比 %.4f%%，平均执行周期数 %.2f", insts[CSR], (double)insts[CSR] / (double)inst_nums * 100, (double)inst_clk[CSR] / (double)insts[CSR]);
    Log("execute 指令数量:%lu，占比 %.4f%%，平均执行周期数 %.2f", insts[EXECUTE], (double)insts[EXECUTE] / (double)inst_nums * 100, (double)inst_clk[EXECUTE] / (double)insts[EXECUTE]);
    Log("ifu 平均取指延迟周期为%.2f", (double)ifu_clk / (double)(inst_nums));
    Log("lsu 平均访存延迟周期为%.2f", (double)lsu_clk / (double)(insts[LOAD] + insts[STORE]));

#ifdef CONFIG_ICACHE
    Log("hit_counter = %ld", hit_counter);
    Log("miss_counter = %ld", miss_counter);
    Log("hit_rate = %.6f", (double)hit_counter/(hit_counter + miss_counter));
    Log("miss_time = %ld", miss_time);
    Log("缺失代价为 %.2f", (double)miss_time / (double) miss_counter);
    Log("AMAT = %.2f", hit_time + 
        (double)miss_time / (double) miss_counter *  ((double)miss_counter / (double)(miss_counter + hit_counter)));
#endif
  }

