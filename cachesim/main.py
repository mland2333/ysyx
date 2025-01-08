import os
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed

# 参数设置
num_blocks_list = [8, 16, 32, 64]  # NUM_BLOCKS 参数值
num_ways_list = [1, 2, 4, 8]       # NUM_WAYS 参数值
data_width_list = [1, 2, 4]
# 获取命令行传入的 ITRACE 参数
itrace_file = sys.argv[1] if len(sys.argv) > 1 else 'trace.txt'  # 默认指令跟踪文件

# 结果列表
result_list = []  # 用于存储结果按顺序输出

# 执行模拟的函数
def run_simulation(num_blocks, num_ways, data_width, itrace_file):
    try:
        # 执行模拟命令并传递运行时参数
        run_command = [
            "./main", 
            "itrace/" + itrace_file, 
            str(num_blocks), 
            str(num_ways),
            str(data_width*4)
        ]
        result = subprocess.run(run_command, capture_output=True, text=True)

        # 提取命中率数据
        output = result.stdout
        for line in output.splitlines():
            if "hit_counter" in line and "miss_counter" in line:
                hit, miss = map(int, [
                    line.split('=')[1].split(',')[0].strip(),
                    line.split('=')[2].strip()
                ])
                hit_rate = hit / (hit + miss) if (hit + miss) > 0 else 0.0
                return num_blocks, num_ways, data_width, round(hit_rate, 4), hit, miss

        # 若未找到命中率数据，则返回错误信息
        return num_blocks, num_ways, data_width, "Error: No output", 0, 0
    except Exception as e:
        return num_blocks, num_ways, data_width, f"Error: {str(e)}", 0, 0

# 使用多进程执行测试
def main():
    tasks = []
    with ProcessPoolExecutor() as executor:  # 使用多进程池
        for num_blocks in num_blocks_list:
            for num_ways in num_ways_list:
                for data_width in data_width_list:
                    tasks.append(executor.submit(run_simulation, num_blocks, num_ways, data_width, itrace_file))

        for future in as_completed(tasks):
            result = future.result()
            if result is not None:  # 确保结果有效
                result_list.append(result)

    # 按顺序排序结果并打印
    result_list.sort(key=lambda x: (x[0], x[1], x[2]))  # 按 num_blocks 和 num_ways 升序排序
    print(" NUM_BLOCKS | NUM_WAYS | DATA_WIDTH | Hit Rate | Hit Counter | Miss Counter")
    print("------------|----------|------------|----------|-------------|-------------")
    for num_blocks, num_ways, data_width, hit_rate, hit, miss in result_list:
        print(f"{num_blocks:^11} | {num_ways:^8} | {data_width:^10} | {hit_rate:^8} | {hit:^11} | {miss:^13}")

if __name__ == "__main__":
    main()









