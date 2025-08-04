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

# 临时文件清理变量
TEMP_FILE_TO_CLEANUP=""
SHOULD_CLEANUP=false

# 清理函数
cleanup_temp_file() {
    if [[ "$SHOULD_CLEANUP" == true && -n "$TEMP_FILE_TO_CLEANUP" && -f "$TEMP_FILE_TO_CLEANUP" ]]; then
        rm -f "$TEMP_FILE_TO_CLEANUP"
        echo -e "\n${BLUE}已清理临时文件: $TEMP_FILE_TO_CLEANUP${NC}" >&2
    fi
}

# 信号处理
trap cleanup_temp_file EXIT INT TERM

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

# 检查并安装官方speedtest CLI
check_speedtest_cli() {
    if command -v speedtest &> /dev/null; then
        echo -e "${GREEN}✓ 官方 Speedtest CLI 已安装${NC}"
        
        # 检查是否需要接受许可协议
        echo -e "${BLUE}正在验证 Speedtest CLI 配置...${NC}"
        if ! speedtest --help &> /dev/null; then
            echo -e "${YELLOW}⚠ 需要接受许可协议，正在自动处理...${NC}"
            if speedtest --accept-license --accept-gdpr --format=human-readable &> /dev/null; then
                echo -e "${GREEN}✓ 许可协议已自动接受${NC}"
            else
                echo -e "${RED}错误: 无法自动接受许可协议，请手动运行: speedtest --accept-license --accept-gdpr${NC}"
                exit 1
            fi
        fi
        return 0
    fi
    
    echo -e "${YELLOW}⚠ 官方 Speedtest CLI 未检测到，正在自动安装...${NC}"
    
    # 检测操作系统类型
    local os_type=""
    local install_success=false
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        os_type="$ID"
    elif [[ -f /etc/redhat-release ]]; then
        os_type="centos"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
    fi
    
    case $os_type in
        ubuntu|debian)
            echo -e "${BLUE}检测到 Ubuntu/Debian 系统，正在安装...${NC}"
            if command -v sudo &> /dev/null; then
                curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash && \
                sudo apt-get install -y speedtest && install_success=true
            else
                echo -e "${RED}错误: 需要 sudo 权限进行安装${NC}"
                exit 1
            fi
            ;;
        centos|rhel|fedora)
            echo -e "${BLUE}检测到 CentOS/RHEL/Fedora 系统，正在安装...${NC}"
            if command -v sudo &> /dev/null; then
                curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash && \
                sudo yum install -y speedtest && install_success=true
            else
                echo -e "${RED}错误: 需要 sudo 权限进行安装${NC}"
                exit 1
            fi
            ;;
        macos)
            echo -e "${BLUE}检测到 macOS 系统，正在安装...${NC}"
            if command -v brew &> /dev/null; then
                brew tap teamookla/speedtest && \
                brew install speedtest && install_success=true
            else
                echo -e "${RED}错误: 需要 Homebrew 进行安装，请先安装 Homebrew${NC}"
                echo "安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}错误: 不支持的操作系统 ${os_type}${NC}"
            echo -e "${YELLOW}请手动安装 Ookla Speedtest CLI:${NC}"
            echo "  Ubuntu/Debian: sudo apt-get install speedtest"
            echo "  CentOS/RHEL: sudo yum install speedtest"
            echo "  macOS: brew install speedtest"
            echo "  或者从官方网站下载: https://www.speedtest.net/apps/cli"
            exit 1
            ;;
    esac
    
# 验证安装是否成功并自动接受许可
    if [[ "$install_success" == true ]] && command -v speedtest &> /dev/null; then
        echo -e "${GREEN}✓ 官方 Speedtest CLI 安装成功${NC}"
        
        # 自动接受许可协议（首次使用）
        echo -e "${BLUE}正在配置 Speedtest CLI...${NC}"
        if speedtest --accept-license --accept-gdpr --format=human-readable &> /dev/null; then
            echo -e "${GREEN}✓ 许可协议已自动接受${NC}"
        else
            echo -e "${YELLOW}⚠ 许可协议配置可能需要手动确认${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}错误: 安装失败，请手动安装${NC}"
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
    echo "  -u         下载远程servers.txt文件并执行测试"
    echo "  -l         列出附近的服务器ID"
    echo "  -h         显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 12345 67890 54321"
    echo "  $0 -f servers.txt"
    echo "  $0 -u"
    echo ""
}

# 列出附近的服务器
list_servers() {
    echo -e "${BLUE}正在获取附近的服务器列表...${NC}"
    speedtest --servers
}

# 下载远程servers.txt文件
download_servers_file() {
    local remote_url="https://raw.githubusercontent.com/youtonghy/global-speedtest/refs/heads/main/servers.txt"
    local local_file="${SCRIPT_DIR}/servers.txt"
    
    echo -e "${BLUE}正在下载远程服务器列表...${NC}" >&2
    
    # 检查curl或wget是否可用
    if command -v curl &> /dev/null; then
        if curl -s -o "$local_file" "$remote_url"; then
            echo -e "${GREEN}服务器列表下载成功: $local_file${NC}" >&2
            echo "$local_file"
        else
            echo -e "${RED}下载失败: 无法从 $remote_url 下载文件${NC}" >&2
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -q -O "$local_file" "$remote_url"; then
            echo -e "${GREEN}服务器列表下载成功: $local_file${NC}" >&2
            echo "$local_file"
        else
            echo -e "${RED}下载失败: 无法从 $remote_url 下载文件${NC}" >&2
            exit 1
        fi
    else
        echo -e "${RED}错误: 未找到 curl 或 wget 命令${NC}" >&2
        echo -e "${YELLOW}请先安装 curl 或 wget:${NC}" >&2
        echo "  Ubuntu/Debian: sudo apt-get install curl" >&2
        echo "  CentOS/RHEL: sudo yum install curl" >&2
        echo "  macOS: curl 通常已预装" >&2
        exit 1
    fi
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
    local downloaded_file=""
    local cleanup_file=false
    
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
            -u|--update)
                downloaded_file=$(download_servers_file)
                servers=($(read_servers_from_file "$downloaded_file"))
                cleanup_file=true
                # 设置全局清理变量
                TEMP_FILE_TO_CLEANUP="$downloaded_file"
                SHOULD_CLEANUP=true
                shift
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
    
    # 如果是通过-u参数下载的文件，删除临时文件
    if [[ "$cleanup_file" == true && -f "$downloaded_file" ]]; then
        rm -f "$downloaded_file"
        echo -e "${BLUE}已清理临时文件: $downloaded_file${NC}"
        # 重置清理变量，避免EXIT trap重复执行
        SHOULD_CLEANUP=false
    fi
    
    echo -e "${GREEN}所有测试完成！结果已保存到 ${LOG_FILE}${NC}"
}

# 检查参数并运行
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

main "$@"
