# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Bash script-based network speed testing tool that performs batch speedtests against specified servers using the official Ookla Speedtest CLI.

## Key Commands

### Core Usage
```bash
# Test single server
./speedtest.sh 12345

# Test multiple servers
./speedtest.sh 12345 67890 54321

# Test from server list file
./speedtest.sh -f servers.txt

# Download and test from remote server list
./speedtest.sh -u

# List nearby servers
./speedtest.sh -l

# Show help
./speedtest.sh -h
```

### Setup Requirements
- Requires official Ookla Speedtest CLI installation
- Ubuntu/Debian: `sudo apt-get install speedtest`
- CentOS/RHEL: `sudo yum install speedtest`
- macOS: `brew install speedtest`

## Architecture

### Main Components
- **speedtest.sh**: Main bash script (340 lines)
- **speedtest_result/**: Directory storing timestamped log files
- **servers.txt**: Server ID list file (comment support with `#`)

### Key Features
- Batch testing with progress tracking
- Remote server list download via curl/wget
- Colored terminal output
- Detailed logging with timestamps
- Server ID comments support
- Automatic cleanup of temporary files

### Output Format
Results saved to `speedtest_result/speedtest_results_YYYYMMDD_HHMMSS.log`:
```
服务器名称 | 延迟 | 下载速度 | 上传速度 | 丢包率 | 时间
```

### Remote Server List
Default servers URL: `https://raw.githubusercontent.com/youtonghy/global-speedtest/refs/heads/main/servers.txt`