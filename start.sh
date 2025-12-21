#!/bin/bash
set -e

echo "=== 启动 MK48 HTTP 服务器 ==="
PORT=${PORT:-8080}
echo "端口: $PORT"

# 必要检查
[ -f "./mk48-plus-bin" ] || { echo "错误: 无 mk48-plus-bin"; exit 1; }
chmod +x ./mk48-plus-bin 2>/dev/null || true

# 前端检查
if [ ! -d "public" ]; then
    mkdir -p public
    echo '<!DOCTYPE html><html><head><title>MK48 HTTP Server</title></head><body><h1>MK48 Game Server</h1><p>Running in HTTP mode</p></body></html>' > public/index.html
    echo "创建了简易 public/index.html"
fi

# 创建健康检查文件（给直接访问用）
echo "OK" > public/healthz

# 设置环境变量，防止 MK48 内部重定向
export MK48_NO_REDIRECT=1
export DISABLE_SSL_REDIRECT=true

echo "启动命令: ./mk48-plus-bin --http-port $PORT --ip-address 0.0.0.0 --debug-http info"

# 启动 - 纯 HTTP，无证书参数
exec ./mk48-plus-bin \
    --http-port "$PORT" \
    --server-id 1 \
    --debug-http info \
    --debug-game info \
    --debug-core error \
    --debug-sockets warn \
    --http-bandwidth-limit 100000 \
    --ip-address 0.0.0.0 \
    --client-authenticate-burst 10
