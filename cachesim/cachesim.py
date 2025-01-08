import os
import subprocess
import concurrent.futures
import argparse
# 定义参数范围
NUM_BLOCKS = [32, 64, 128]  # 可调整的 NUM_BLOCKS 参数
NUM_WAYS = [2, 4, 8]       # 可调整的 NUM_WAYS 参数

# 定义 NEMU_HOME 路径
MAKE_HOME = "/home/mland/ysyx-workbench/am-kernels/tests/cpu-tests"  # 替换为实际的路径
IMAGE = "test_image"         # 镜像文件名


# 定义任务执行函数
def run_make(num_blocks, num_ways, run_file):
    # 构造命令
    command = f"make -C {MAKE_HOME} run ARCH=riscv323-cachesim ALL={run_file} NUM_BLOCKS={num_blocks} NUM_WAYS={num_ways}"
    try:
        # 执行命令并捕获输出
        result = subprocess.run(command, shell=True, text=True, capture_output=True)

        # 从输出中提取 hit_counter 和 miss_counter
        output = result.stdout
        hit_counter = 0
        miss_counter = 0
        for line in output.splitlines():
            if "hit_counter" in line:
                hit_counter = int(line.split('=')[-1].strip())
            elif "miss_counter" in line:
                miss_counter = int(line.split('=')[-1].strip())

        # 返回结果
        return (num_blocks, num_ways, hit_counter, miss_counter)

    except Exception as e:
        print(f"Error running NUM_BLOCKS={num_blocks}, NUM_WAYS={num_ways}: {str(e)}")
        return (num_blocks, num_ways, None, None)

def main(run_file):
    # 创建任务列表
    tasks = [(num_blocks, num_ways) for num_blocks in NUM_BLOCKS for num_ways in NUM_WAYS]

    # 使用多线程执行任务
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count()) as executor:  # 自动检测线程数
        futures = {executor.submit(run_make, task[0], task[1], run_file): task for task in tasks}
        for future in concurrent.futures.as_completed(futures):
            results.append(future.result())

    # 将结果写入文件
    print("NUM_BLOCKS NUM_WAYS HIT_COUNTER MISS_COUNTER")
    for res in results:
        print(f"{res[0]} {res[1]} {res[2]} {res[3]}")

if __name__ == "__main__":
    # 使用 argparse 处理命令行参数
    parser = argparse.ArgumentParser(description="Run cachesim with multiple configurations.")
    parser.add_argument("run_file", type=str, help="run_file")
    args = parser.parse_args()

    # 执行主程序
    main(args.run_file)

