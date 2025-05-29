#include "perf.h"
#include "debug/log.h"
#include <iostream>
#include <iomanip>
#include <array>

// 使用宏自动生成事件名称数组
constexpr std::array<const char*, static_cast<size_t>(PerfEvent::MAX)> event_names = {
#define X(name) #name,
    PERF_EVENTS
#undef X
};

// 使用宏自动生成计数器名称数组
constexpr std::array<const char*, static_cast<size_t>(PerfCounter::MAX)> counter_names = {
#define X(name) #name,
    PERF_COUNTERS
#undef X
};

// 全局实例
PerfMonitor g_perf_monitor;

PerfMonitor::PerfMonitor() {
    init_names();
    init_event_map();
}

void PerfMonitor::init_names() {
    // 初始化计数器名称和属性
    for (size_t i = 0; i < counters_.size(); ++i) {
        counters_[i].name = counter_names[i];
        counters_[i].value = 0;
        counters_[i].is_ratio = (static_cast<PerfCounter>(i) == PerfCounter::PERF_IPC || 
                                static_cast<PerfCounter>(i) == PerfCounter::PERF_CPI);
    }
    
    // 初始化事件名称
    for (size_t i = 0; i < events_.size(); ++i) {
        events_[i].name = event_names[i];
        events_[i].trigger_count = 0;
    }
}

void PerfMonitor::init_event_map() {
    event_name_map_.clear();
    for (size_t i = 0; i < events_.size(); ++i) {
        event_name_map_[events_[i].name] = static_cast<PerfEvent>(i);
    }
}

void PerfMonitor::trigger_event(PerfEvent event) {
    const auto event_idx = static_cast<size_t>(event);
    if (event_idx >= events_.size()) return;
    
    // 更新事件统计
    events_[event_idx].trigger_count++;
    
    // 根据事件类型更新对应的计数器
    switch (event) {
        case PerfEvent::EVENT_CYCLE:
            counters_[static_cast<size_t>(PerfCounter::PERF_CYCLE_COUNT)].value++;
            break;
        case PerfEvent::EVENT_INST_COMMIT:
            counters_[static_cast<size_t>(PerfCounter::PERF_INST_COUNT)].value++;
            break;
        case PerfEvent::EVENT_INST_RETIRE:
            counters_[static_cast<size_t>(PerfCounter::PERF_INST_RETIRED)].value++;
            break;
        default:
            break;
    }
}

void PerfMonitor::trigger_event_by_name(const std::string& event_name) {
    auto it = event_name_map_.find(event_name);
    if (it != event_name_map_.end()) {
        trigger_event(it->second);
    } else {
        std::cout << "Warning: Unknown event name: " << event_name << std::endl;
    }
}

uint64_t PerfMonitor::get_counter(PerfCounter counter) const {
    const auto counter_idx = static_cast<size_t>(counter);
    if (counter_idx >= counters_.size()) return 0;
    return counters_[counter_idx].value;
}

double PerfMonitor::get_counter_ratio(PerfCounter counter) const {
    const auto counter_idx = static_cast<size_t>(counter);
    if (counter_idx >= counters_.size() || !counters_[counter_idx].is_ratio) {
        return 0.0;
    }
    
    const uint64_t cycles = get_counter(PerfCounter::PERF_CYCLE_COUNT);
    const uint64_t insts = get_counter(PerfCounter::PERF_INST_COUNT);
    
    if (cycles == 0 || insts == 0) return 0.0;
    
    switch (counter) {
        case PerfCounter::PERF_IPC:
            return static_cast<double>(insts) / cycles;
        case PerfCounter::PERF_CPI:
            return static_cast<double>(cycles) / insts;
        default:
            return 0.0;
    }
}

const std::string& PerfMonitor::get_counter_name(PerfCounter counter) const {
    const auto counter_idx = static_cast<size_t>(counter);
    static const std::string unknown = "UNKNOWN";
    if (counter_idx >= counters_.size()) return unknown;
    return counters_[counter_idx].name;
}

const std::string& PerfMonitor::get_event_name(PerfEvent event) const {
    const auto event_idx = static_cast<size_t>(event);
    static const std::string unknown = "UNKNOWN";
    if (event_idx >= events_.size()) return unknown;
    return events_[event_idx].name;
}

void PerfMonitor::print_summary() const {
    std::cout << "\n=== Performance Summary ===" << std::endl;
    std::cout << "Total Cycles: " << get_counter(PerfCounter::PERF_CYCLE_COUNT) << std::endl;
    std::cout << "Instructions Committed: " << get_counter(PerfCounter::PERF_INST_COUNT) << std::endl;
    std::cout << "Instructions Retired: " << get_counter(PerfCounter::PERF_INST_RETIRED) << std::endl;
    
    if (get_counter(PerfCounter::PERF_CYCLE_COUNT) > 0 && get_counter(PerfCounter::PERF_INST_COUNT) > 0) {
        std::cout << "IPC: " << std::fixed << std::setprecision(3) 
                  << get_counter_ratio(PerfCounter::PERF_IPC) << std::endl;
        std::cout << "CPI: " << std::fixed << std::setprecision(3) 
                  << get_counter_ratio(PerfCounter::PERF_CPI) << std::endl;
    }
    
    std::cout << "\n=== Event Statistics ===" << std::endl;
    for (const auto& event : events_) {
        std::cout << event.name << ": " << event.trigger_count << std::endl;
    }
}

void PerfMonitor::reset_all() {
    for (auto& counter : counters_) {
        counter.value = 0;
    }
    for (auto& event : events_) {
        event.trigger_count = 0;
    }
}

// C接口兼容性实现
extern "C" {
    void perf_init() {
        g_perf_monitor.reset_all();
    }
    
    void perf_trigger_event_by_name(const char* event_name) {
        g_perf_monitor.trigger_event_by_name(std::string(event_name));
    }
    
    void perf_print_summary() {
        g_perf_monitor.print_summary();
    }
    
    void perf_reset_all() {
        g_perf_monitor.reset_all();
    }
}

