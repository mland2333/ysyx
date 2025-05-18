import os
import subprocess
import re
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

# 定义测试文件名称列表
test_files = ["qsort", "queen", "bf", "fib", "sieve", "15pz", "dinic", "lzip", "ssort", "md5"]
# 数据提取的正则表达式
perf_patterns = {
    "total_clk": r"total host clk = (\d+)",
    "total_inst": r"total host instructions = (\d+)",
    "hit_counter": r"hit_counter = (\d+)",
    "miss_counter": r"miss_counter = (\d+)",
    "miss_time": r"miss_time = (\d+)"
}

# 结果统计
results = {}

# 工作目录
bench_dir = "/home/mland/ysyx-workbench/am-kernels/benchmarks/microbench"
npc_dir = "/home/mland/ysyx-workbench/npc"
main_args = ""
def run_make(test_name):
    """串行执行 make"""
    os.chdir(bench_dir)
    make_cmd = f"make ARCH=riscv32e-ysyxsoc compile -B NPCFLAGS='-b -p' mainargs=train TEST={test_name}"
    try:
        subprocess.run(make_cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"[INFO] Make completed for {test_name}")
        return test_name, True
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Make failed for {test_name}: {e}")
        return test_name, False

def run_main(cmd, test_name, args):
    """并行执行 ./build/main 并解析结果"""
    img_name = "microbench_" + test_name + "-riscv32e-ysyxsoc.bin"
    run_cmd = f"{npc_dir}/{cmd} {bench_dir}/build/{img_name} {args}"
    print(f"[INFO] run {run_cmd}")
    try:
        output = subprocess.run(run_cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output_text = output.stdout.decode("utf-8")
        print(f"[INFO] Execution completed for {test_name}")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Running main failed for {test_name}")
        return test_name, None

    # 解析输出数据
    data = {}
    for key, pattern in perf_patterns.items():
        match = re.search(pattern, output_text)
        if match:
            data[key] = int(match.group(1))
        else:
            data[key] = None

    return test_name, data

def main():
    # 1. 串行执行 make
    for test_name in test_files:
        _, success = run_make(test_name)
        if not success:
            print(f"[ERROR] Skipping {test_name} due to make failure.")
            continue
    cmd = sys.argv[1]
    main_args = sys.argv[2]
    # 2. 并行执行 ./build/main
    with ThreadPoolExecutor() as executor:
        future_to_test = {executor.submit(run_main, cmd, test, main_args): test for test in test_files}
        for future in as_completed(future_to_test):
            test_name = future_to_test[future]
            try:
                test_name, data = future.result()
                if data:
                    results[test_name] = data
            except Exception as exc:
                print(f"[ERROR] Test {test_name} generated an exception: {exc}")

    # 3. 打印收集到的结果
    print("\n[Results]")
    for test_name, data in results.items():
        print(f"{test_name}: {data}")

    # 4. 汇总统计
    summary = {key: 0 for key in perf_patterns.keys()}
    for data in results.values():
        for key in perf_patterns.keys():
            if data[key] is not None:
                summary[key] += data[key]

    print("\n[Summary]")
    for key, value in summary.items():
        print(f"{key}: {value}")

if __name__ == "__main__":
    main()

