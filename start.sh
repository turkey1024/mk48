#!/bin/bash
# diagnostic_start.sh - 重定向问题诊断脚本
set -e

echo "=========================================="
echo "🔍 MK48 服务器重定向问题诊断工具"
echo "=========================================="
echo "诊断时间: $(date)"
echo "当前目录: $(pwd)"
echo ""

# ==================== 1. 环境检查 ====================
echo "=== 1. 环境变量检查 ==="
echo "PORT 环境变量: '${PORT:-未设置}'"
echo "PWD: $(pwd)"
echo "用户: $(whoami)"
echo "主机名: $(hostname)"
echo ""

# ==================== 2. 文件系统检查 ====================
echo "=== 2. 文件系统检查 ==="
echo "二进制文件:"
file ./mk48-plus-bin
ls -lh ./mk48-plus-bin
echo ""

echo "public/ 目录检查:"
if [ -d "public" ]; then
    echo "✅ public 目录存在"
    find public -type f -name "*.html" -o -name "*.js" -o -name "*.css" | head -10
    if [ -f "public/index.html" ]; then
        echo "✅ 找到 index.html"
        echo "  文件大小: $(wc -l < public/index.html) 行"
        echo "  首行内容: $(head -1 public/index.html)"
    else
        echo "⚠️  未找到 public/index.html"
        find public -type f | head -5
    fi
else
    echo "❌ public 目录不存在"
fi
echo ""

# ==================== 3. 网络端口检查 ====================
echo "=== 3. 网络端口检查 ==="
DIAG_PORT=${PORT:-18080}  # 使用诊断端口，避免冲突
echo "将使用诊断端口: $DIAG_PORT"

# 检查端口占用
echo "端口 $DIAG_PORT 占用情况:"
if netstat -tuln 2>/dev/null | grep ":$DIAG_PORT" >/dev/null; then
    echo "⚠️  端口 $DIAG_PORT 已被占用，尝试其他端口..."
    DIAG_PORT=$((DIAG_PORT + 1))
    echo "改为使用端口: $DIAG_PORT"
fi
echo ""

# ==================== 4. 服务器启动测试 ====================
echo "=== 4. 启动服务器测试 ==="
echo "启动命令:"
CMD="./mk48-plus-bin --http-port $DIAG_PORT --server-id 1 --debug-http debug --debug-game info"
echo "  $CMD"
echo ""

# 设置环境变量（避免重定向循环）
export HTTP_X_FORWARDED_PROTO=https
export HTTP_X_FORWARDED_PORT=443
export RENDER_EXTERNAL_HOSTNAME="turkey-mk.onrender.com"
export RUST_LOG=debug
export RUST_BACKTRACE=1

# 启动服务器（后台运行）
$CMD > server.log 2>&1 &
SERVER_PID=$!
echo "✅ 服务器已启动 (PID: $SERVER_PID)"
echo "日志输出到: server.log"
echo ""

# 等待服务器启动
echo "等待服务器初始化 (5秒)..."
sleep 5

# 检查进程状态
if kill -0 $SERVER_PID 2>/dev/null; then
    echo "✅ 服务器进程运行正常"
else
    echo "❌ 服务器进程已退出"
    echo "=== 最后的日志输出 ==="
    tail -50 server.log
    exit 1
fi
echo ""

# ==================== 5. 本地连接测试 ====================
echo "=== 5. 本地连接测试 ==="
echo "测试 1: 直接访问根路径"
curl -v -s "http://localhost:$DIAG_PORT/" 2>&1 | \
    grep -E "(HTTP\/|< Location:|< Content-Type:|< Set-Cookie:|> GET|> Host:)" | \
    head -20

echo ""
echo "测试 2: 模拟外部访问（带 Host 头）"
curl -v -s \
    -H "Host: turkey-mk.onrender.com" \
    -H "X-Forwarded-Proto: https" \
    -H "X-Forwarded-Port: 443" \
    "http://localhost:$DIAG_PORT/" 2>&1 | \
    grep -E "(HTTP\/|< Location:|< Content-Type:|< Set-Cookie:)" | \
    head -15

echo ""
echo "测试 3: 访问静态文件"
if [ -f "public/index.html" ]; then
    curl -v -s "http://localhost:$DIAG_PORT/index.html" 2>&1 | \
        grep -E "(HTTP\/|< Location:|< Content-Type:)" | head -10
else
    echo "跳过（无 public/index.html）"
fi
echo ""

# ==================== 6. 日志分析 ====================
echo "=== 6. 服务器日志分析 ==="
echo "搜索 'redirect'、'location'、'301'、'302':"
grep -i -E "(redirect|location| 30[12] |rewrit)" server.log | head -15

echo ""
echo "搜索最近的请求处理:"
tail -30 server.log | grep -E "(DEBUG|INFO|WARN|ERROR|Request|response)" | head -20
echo ""

# ==================== 7. 关键信息汇总 ====================
echo "=== 7. 诊断摘要 ==="
echo "1. ✅ 服务器已在端口 $DIAG_PORT 启动"
echo "2. ✅ 进程运行正常 (PID: $SERVER_PID)"
echo "3. 📝 详细日志: server.log"

# 检查是否有重定向
REDIRECT_COUNT=$(grep -c -i "location:" server.log)
if [ "$REDIRECT_COUNT" -gt 0 ]; then
    echo "4. 🔄 检测到 $REDIRECT_COUNT 次重定向"
    echo "   查看日志了解重定向目标"
else
    echo "4. ✅ 未检测到重定向"
fi

# 检查静态资源
if [ -f "public/index.html" ]; then
    echo "5. ✅ 找到静态资源文件"
else
    echo "5. ⚠️  缺少静态资源文件（可能是内嵌或不需要）"
fi

echo ""
echo "=========================================="
echo "下一步:"
echo "1. 检查上面的 '本地连接测试' 结果"
echo "2. 查看完整的 server.log 文件"
echo "3. 如果看到 'Location:' 头，那就是重定向源头"
echo "=========================================="

# 保持运行
echo ""
echo "服务器保持运行中..."
echo "按 Ctrl+C 停止服务器并结束诊断"
echo ""

# 清理函数
cleanup() {
    echo ""
    echo "正在停止服务器..."
    kill $SERVER_PID 2>/dev/null
    wait $SERVER_PID 2>/dev/null
    echo "诊断完成。"
    exit 0
}

trap cleanup INT TERM
wait $SERVER_PID
