#!/bin/bash
set -e

echo "========================================"
echo "    🎮 MK48 Server - 启动中...          "
echo "========================================"

RENDER_PORT=${PORT:-8443}
BINARY="./mk48-plus-bin"

# 检查文件是否存在
if [ ! -f "$BINARY" ]; then
    echo "❌ 错误: 未找到 $BINARY"
    ls -la
    exit 1
fi

# 设置可执行权限
chmod +x "$BINARY" 2>/dev/null || true

# 构建参数数组
args=(
    # 必需参数
    "--https-port" "$RENDER_PORT"
    "--host" "0.0.0.0"
    
    # 调试日志参数（使用 release 构建的默认值）
    "--debug-http" "error"      # release 默认
    "--debug-game" "error"      # release 默认
    "--debug-plasma" "warn"     # release 默认
    "--debug-engine" "warn"     # release 默认
    
    # 性能参数（Render 内存限制优化）
    "--http-bandwidth-limit" "100000"
    "--client-authenticate-burst" "5"
    
    # 可选：如果支持 domain_backup 参数
    # "--domain-backup" "./domain_backup.json"
)

echo "🌐 端口: $RENDER_PORT"
echo "📁 二进制: $(file "$BINARY")"
echo "⚙️  参数:"
for ((i=0; i<${#args[@]}; i+=2)); do
    echo "  ${args[i]} = ${args[i+1]}"
done
echo "========================================"

# 执行
exec "$BINARY" "${args[@]}"
