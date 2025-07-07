# Speedtest 批量测速脚本使用说明

## 功能介绍
这个脚本可以自动调用官方 Speedtest CLI 对指定的服务器进行批量测速，并将结果保存到日志文件中。

## 前置条件
确保系统已安装官方 Speedtest CLI：

### Ubuntu/Debian 安装方法
```bash
# 添加官方 Ookla 仓库
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash

# 安装 Speedtest CLI
sudo apt-get install speedtest
```

### CentOS/RHEL/Fedora 安装方法
```bash
# 添加官方 Ookla 仓库
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash

# 安装 Speedtest CLI
sudo yum install speedtest
# 或者对于较新版本
sudo dnf install speedtest
```

### macOS 安装方法
```bash
# 使用 Homebrew
brew tap teamookla/speedtest
brew update
brew install speedtest --force
```

### 验证安装
```bash
speedtest --version
```

**注意：** 如果系统中已安装第三方的 `speedtest-cli`，建议先卸载以避免冲突：
```bash
sudo apt remove speedtest-cli  # Ubuntu/Debian
sudo yum remove speedtest-cli   # CentOS/RHEL
```

## 使用方法

### 1. 基本用法
```bash
# 测试单个服务器
./speedtest.sh 12345

# 测试多个服务器
./speedtest.sh 12345 67890 54321
```

### 2. 从文件读取服务器列表
```bash
# 使用预设的服务器列表文件
./speedtest.sh -f servers.txt

# 使用自定义文件
./speedtest.sh -f 我的服务器列表.txt

# 使用默认远程服务器列表
./speedtest.sh -u

# 使用指定的URL
./speedtest.sh -f https://raw.githubusercontent.com/youtonghy/global-speedtest/refs/heads/main/servers.txt

# 使用本地文件（兼容原有功能）
./speedtest.sh -f local_servers.txt

# 手动指定服务器ID
./speedtest.sh 12492 46114 36998
```

### 3. 其他选项
```bash
# 显示帮助信息
./speedtest.sh -h

# 列出附近的服务器
./speedtest.sh -l
```

## 输出文件
- 测速结果会保存到脚本所在目录的 `speedtest_result` 子目录
- 文件名格式：`speedtest_results_YYYYMMDD_HHMMSS.log`
- 包含详细的测速结果和时间戳
- 结果格式：服务器名称 | 延迟 | 下载速度 | 上传速度 | 丢包率 | 时间

## 服务器列表文件格式
服务器列表文件格式如下：
```
# 这是注释行
12345    # 这也是注释
67890
54321
```

## 示例
```bash
# 测试预设的全球服务器
./speedtest.sh -f servers.txt

# 使用远程服务器列表
./speedtest.sh -u

# 查看测速结果
cat speedtest_result/speedtest_results_*.log
```

## 注意事项
1. 测速过程中请保持网络稳定
2. 每次测试之间会有1秒的间隔
3. 如果某个服务器测试失败，会记录错误信息但继续测试其他服务器
4. 日志文件会包含完整的测速结果，包括下载速度、上传速度、延迟和丢包率
5. 首次运行官方 Speedtest CLI 时，需要接受许可条款
6. 官方 CLI 比第三方版本有更好的性能和准确性

## 默认服务器列表
DEFAULT_SERVERS_URL="https://raw.githubusercontent.com/youtonghy/global-speedtest/refs/heads/main/servers.txt" 