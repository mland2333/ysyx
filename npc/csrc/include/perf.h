#ifndef __PERF_H__
#define __PERF_H__

#include <cstdint>
#include <string>
#include <unordered_map>
#include <array>

// 使用宏定义事件列表，实现自动注册
#define PERF_EVENTS \
    X(EVENT_CYCLE) \
    X(EVENT_INST_COMMIT) \
    X(EVENT_INST_RETIRE)

// 使用宏定义性能计数器列表
#define PERF_COUNTERS \
    X(PERF_CYCLE_COUNT) \
    X(PERF_INST_COUNT) \
    X(PERF_INST_RETIRED) \
    X(PERF_IPC) \
    X(PERF_CPI)

// 生成事件枚举
enum class PerfEvent : int {
#define X(name) name,
    PERF_EVENTS
#undef X
    MAX
};

// 生成性能计数器枚举
enum class PerfCounter : int {
#define X(name) name,
    PERF_COUNTERS
#undef X
    MAX
};

// 性能计数器数据结构
struct PerfCounterData {
    std::string name;
    uint64_t value = 0;
    bool is_ratio = false;
};

// 事件数据结构
struct PerfEventData {
    std::string name;
    uint64_t trigger_count = 0;
};

// 现代C++性能监控类
class PerfMonitor {
private:
    std::array<PerfCounterData, static_cast<size_t>(PerfCounter::MAX)> counters_;
    std::array<PerfEventData, static_cast<size_t>(PerfEvent::MAX)> events_;
    std::unordered_map<std::string, PerfEvent> event_name_map_;
    
    void init_names();
    void init_event_map();

public:
    PerfMonitor();
    
    // 事件触发接口
    void trigger_event(PerfEvent event);
    void trigger_event_by_name(const std::string& event_name);
    
    // 性能数据获取接口
    uint64_t get_counter(PerfCounter counter) const;
    double get_counter_ratio(PerfCounter counter) const;
    const std::string& get_counter_name(PerfCounter counter) const;
    const std::string& get_event_name(PerfEvent event) const;
    
    // 性能数据输出
    void print_summary() const;
    void reset_all();
};

// 全局实例
extern PerfMonitor g_perf_monitor;

// C接口兼容性（用于SystemVerilog调用）
extern "C" {
    void perf_init();
    void perf_trigger_event_by_name(const char* event_name);
    void perf_print_summary();
    void perf_reset_all();
}

// 便捷宏定义
#define PERF_COUNT_CYCLE() g_perf_monitor.trigger_event(PerfEvent::EVENT_CYCLE)
#define PERF_COUNT_INST() g_perf_monitor.trigger_event(PerfEvent::EVENT_INST_COMMIT)

#endif
