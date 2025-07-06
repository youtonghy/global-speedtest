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

# 声明关联数组来存储服务器备注信息
declare -A SERVER_COMMENTS

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

# 解析speedtest结果并格式化
parse_speedtest_result() {
    local result="$1"
    local server_id="$2"
    local comment="$3"
    
    # 提取各项数据
    local server_info=$(echo "$result" | grep -i "server:" | sed 's/.*Server: *//')
    local ping=$(echo "$result" | grep -i "latency:" | sed 's/.*Latency: *//' | sed 's/ *ms.*//')
    local download=$(echo "$result" | grep -i "download:" | sed 's/.*Download: *//' | sed 's/ *Mbps.*//')
    local upload=$(echo "$result" | grep -i "upload:" | sed 's/.*Upload: *//' | sed 's/ *Mbps.*//')
    local packet_loss=$(echo "$result" | grep -i "packet loss:" | sed 's/.*Packet Loss: *//' | sed 's/%.*//') 
    
    # 如果没有找到丢包率，默认为0.0
    if [[ -z "$packet_loss" ]]; then
        packet_loss="0.0"
    fi
    
    # 如果有备注，使用备注作为服务器名称，否则使用解析的服务器信息
    local display_name="$server_info"
    if [[ -n "$comment" ]]; then
        display_name="$comment"
    fi
    
    # 生成格式化的日志条目
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${display_name} | ${ping} ms | ${download} Mbps | ${upload} Mbps | ${packet_loss}% | ${timestamp}"
}

# 测试单个服务器
test_server() {
    local server_id="$1"
    local comment="${SERVER_COMMENTS[$server_id]}"
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -n "$comment" ]]; then
        echo -e "${YELLOW}正在测试服务器 ID: ${server_id} (${comment})${NC}"
    else
        echo -e "${YELLOW}正在测试服务器 ID: ${server_id}${NC}"
    fi
    
    # 执行speedtest测试
    local result
    if result=$(speedtest --server-id=${server_id} --format=human-readable 2>&1); then
        if [[ -n "$comment" ]]; then
            echo -e "${GREEN}服务器 ${server_id} (${comment}) 测试完成${NC}"
        else
            echo -e "${GREEN}服务器 ${server_id} 测试完成${NC}"
        fi
        
        # 解析结果并写入格式化的日志
        local formatted_result=$(parse_speedtest_result "$result" "$server_id" "$comment")
        echo "$formatted_result" >> "${LOG_FILE}"
        
    else
        if [[ -n "$comment" ]]; then
            echo -e "${RED}服务器 ${server_id} (${comment}) 测试失败${NC}"
            echo "服务器 ${server_id} (${comment}) 测试失败 - $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
        else
            echo -e "${RED}服务器 ${server_id} 测试失败${NC}"
            echo "服务器 ${server_id} 测试失败 - $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
        fi
    fi
    
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
        # 跳过空行和注释行（以#开头的行）
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            # 提取服务器ID（第一个单词）
            local server_id=$(echo "$line" | awk '{print $1}')
            # 检查是否是有效的数字ID
            if [[ "$server_id" =~ ^[0-9]+$ ]]; then
                servers+=("$server_id")
                
                # 提取备注信息（#后面的内容）
                if [[ "$line" =~ \#(.+)$ ]]; then
                    local comment="${BASH_REMATCH[1]}"
                    # 去除前导和尾随空格
                    comment=$(echo "$comment" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    SERVER_COMMENTS[$server_id]="$comment"
                fi
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
    echo "# Speedtest批量测速结果 - $(date '+%Y-%m-%d %H:%M:%S')" > "${LOG_FILE}"
    echo "# 格式: 服务器名称 | 延迟 | 下载速度 | 上传速度 | 丢包率 | 时间" >> "${LOG_FILE}"
    echo "# 服务器ID列表: ${servers[*]}" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"
    
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
    
    echo "" >> "${LOG_FILE}"
    echo "# 所有测试完成 - $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
    echo -e "${GREEN}所有测试完成！结果已保存到 ${LOG_FILE}${NC}"
}

# 检查参数并运行
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

main "$@"
