import os
import re
import subprocess


def run_microbench():
    ysyx_home = os.getenv("YSYX_HOME", "/path/to/ysyx")
    command = (
        # f"cd {ysyx_home}/am-kernels/benchmarks/microbench && "
        f"cd {ysyx_home}/am-kernels/tests/cpu-tests && "
        f"make ARCH=riscv32e-ysyxsoc run NPCFLAGS=\"-b -p\" ALL=quick-sort"
    )
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    output = result.stdout
    return output


def parse_microbench(output):
    stats = {}
    patterns = {
        "total_host_clk": r"total host clk = (\d+)",
        "total_host_instructions": r"total host instructions = (\d+)",
        "ipc": r"npc's ipc = ([\d\.]+)",
        "hit_counter": r"hit_counter = (\d+)",
        "miss_counter": r"miss_counter = (\d+)",
        "amat": r"AMAT = ([\d\.]+)"
    }
    for key, pattern in patterns.items():
        match = re.search(pattern, output)
        if match:
            stats[key] = float(match.group(1)) if '.' in match.group(1) else int(match.group(1))
    return stats


def run_synthesis():
    yosys_home = os.getenv("YOSYS_HOME", "/path/to/yosys")
    command = f"cd {yosys_home} && make sta"
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return result


def parse_synthesis():
    result_home = os.getenv("NPC_HOME", "/path/to/yosys")
    freq = None
    area = None

    # Parse frequency from `ysyx_24110006.rpt`
    pattern = r'.*\| *([\d.]+) *\|$'
    rpt_file = os.path.join(result_home, "result/ysyx_24110006-1000MHz/ysyx_24110006.rpt")
    with open(rpt_file, 'r') as f:
        for line in f:
            match = re.search(pattern, line)
            if match:
                freq = float(match.group(1))
                break

    # Parse area from `synth_stat.txt`
        stat_file = os.path.join(result_home, "result/ysyx_24110006-1000MHz/synth_stat.txt")
    with open(stat_file, 'r') as f:
        for line in f:
            if "Chip area for top module" in line:
                match = re.search(r":\s*([\d\.]+)", line)
                if match:
                    area = float(match.group(1))
                    break

    return freq, area


def main():
    # Run and parse microbench
    microbench_output = run_microbench()
    print(microbench_output)
    microbench_stats = parse_microbench(microbench_output)

    # Run and parse synthesis
    run_synthesis()
    freq, area = parse_synthesis()

    # Print the final results
    print("仿真周期数  指令数  IPC      综合频率  综合面积  cache命中率  amat")
    print(
        f"{microbench_stats.get('total_host_clk', 'N/A'):^10}"
        f"{microbench_stats.get('total_host_instructions', 'N/A'):^8}"
        f"{microbench_stats.get('ipc', 'N/A'):^11}"
        f"{freq}  "
        f"{area}  "
        f"{round(microbench_stats.get('hit_counter', 'N/A') / (microbench_stats.get('hit_counter', 0) + microbench_stats.get('miss_counter', 1)), 4):^13}"
        f"{microbench_stats.get('amat', 'N/A'):^4}"
    )


if __name__ == "__main__":
    main()

