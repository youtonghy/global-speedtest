#!/bin/bash

# speedtest脚本 - 针对指定服务器ID进行逐个测速
# 用法: ./speedtest.sh [server_id1] [server_id2] [server_id3] ...
# 或者: ./speedtest.sh -f server_list.txt

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_DIR="${SCRIPT_DIR}/speedtest_result"
LOG_FILE="${RESULT_DIR}/speedtest_results_$(date +%Y%m%d_%H%M%S).log"

# 创建结果目录
create_result_dir() {
    if [[ ! -d "${RESULT_DIR}" ]]; then
        mkdir -p "${RESULT_DIR}"
        echo -e "${BLUE}创建结果目录: ${RESULT_DIR}${NC}"
    fi
}

# 检查官方speedtest是否已安装
check_speedtest_cli() {
    if ! command -v speedtest &> /dev/null; then
        echo -e "${RED}错误: 官方 Speedtest CLI 未安装${NC}"
        echo -e "${YELLOW}请先安装 Ookla Speedtest CLI:${NC}"
        echo "  Ubuntu/Debian:"
        echo "    sudo apt-get install curl"
        echo "    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash"
        echo "    sudo apt-get install speedtest"
        echo ""
        echo "  CentOS/RHEL:"
        echo "    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash"
        echo "    sudo yum install speedtest"
        echo ""
        echo "  macOS:"
        echo "    brew tap teamookla/speedtest"
        echo "    brew install speedtest"
        echo ""
        echo "  或者从官方网站下载: https://www.speedtest.net/apps/cli"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Speedtest 批量测速脚本 (使用官方 Ookla Speedtest CLI)${NC}"
    echo ""
    echo "用法:"
    echo "  $0 [server_id1] [server_id2] [server_id3] ..."
    echo "  $0 -f server_list.txt"
    echo "  $0 -l  # 列出附近的服务器"
    echo "  $0 -h  # 显示帮助信息"
    echo ""
    echo "选项:"
    echo "  -f FILE    从文件读取服务器ID列表（每行一个ID）"
    echo "  -l         列出附近的服务器ID"
    echo "  -h         显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 12345 67890 54321"
    echo "  $0 -f servers.txt"
    echo ""
}

# 列出附近的服务器
list_servers() {
    echo -e "${BLUE}正在获取附近的服务器列表...${NC}"
    speedtest --servers
}

# 记录日志
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
    echo -e "${message}"
}

# 测试单个服务器
test_server() {
    local server_id="$1"
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${YELLOW}正在测试服务器 ID: ${server_id}${NC}"
    log_message "开始测试服务器 ID: ${server_id}"
    
    # 执行speedtest测试
    local result
    if result=$(speedtest --server-id=${server_id} --format=human-readable 2>&1); then
        echo -e "${GREEN}服务器 ${server_id} 测试完成${NC}"
        log_message "服务器 ${server_id} 测试成功"
        log_message "测试结果:"
        log_message "${result}"
    else
        echo -e "${RED}服务器 ${server_id} 测试失败${NC}"
        log_message "服务器 ${server_id} 测试失败"
        log_message "错误信息: ${result}"
    fi
    
    log_message "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    log_message "----------------------------------------"
    echo ""
}

# 从文件读取服务器ID列表
read_servers_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}错误: 文件 '$file' 不存在${NC}"
        exit 1
    fi
    
    local servers=()
    while IFS= read -r line; do
        # 跳过空行和注释行
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            # 提取服务器ID（取第一个单词，忽略注释）
            local server_id=$(echo "$line" | awk '{print $1}')
            # 检查是否是有效的数字ID
            if [[ "$server_id" =~ ^[0-9]+$ ]]; then
                servers+=("$server_id")
            fi
        fi
    done < "$file"
    
    echo "${servers[@]}"
}

# 主函数
main() {
    local servers=()
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_servers
                exit 0
                ;;
            -f|--file)
                if [[ -n "$2" ]]; then
                    servers=($(read_servers_from_file "$2"))
                    shift 2
                else
                    echo -e "${RED}错误: -f 选项需要指定文件名${NC}"
                    exit 1
                fi
                ;;
            -*)
                echo -e "${RED}错误: 未知选项 '$1'${NC}"
                show_help
                exit 1
                ;;
            *)
                servers+=("$1")
                shift
                ;;
        esac
    done
    
    # 检查是否有服务器ID
    if [[ ${#servers[@]} -eq 0 ]]; then
        echo -e "${RED}错误: 请指定至少一个服务器ID${NC}"
        show_help
        exit 1
    fi
    
    # 检查speedtest是否安装
    check_speedtest_cli
    
    # 创建结果目录
    create_result_dir
    
    # 创建日志文件
    echo -e "${BLUE}测速结果将保存到: ${LOG_FILE}${NC}"
    log_message "开始批量测速 (使用官方 Ookla Speedtest CLI)"
    log_message "服务器ID列表: ${servers[*]}"
    
    # 逐个测试服务器
    local total=${#servers[@]}
    local current=0
    
    for server_id in "${servers[@]}"; do
        current=$((current + 1))
        echo -e "${BLUE}进度: ${current}/${total}${NC}"
        test_server "$server_id"
        
        # 如果不是最后一个服务器，等待一秒
        if [[ $current -lt $total ]]; then
            sleep 1
        fi
    done
    
    log_message "所有测试完成"
    echo -e "${GREEN}所有测试完成！结果已保存到 ${LOG_FILE}${NC}"
}

# 检查参数并运行
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

main "$@"
