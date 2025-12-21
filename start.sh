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
    echo '<html><body><h1>MK48</h1><p>服务器运行中</p></body></html>' > public/index.html
    echo "⚠️  创建了简易 public/"
fi

# 设置环境变量防止 CA 错误
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# 启动
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
