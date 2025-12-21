#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 ==="

# 关键：MK48 使用固定端口 8080（内部）
PORT=8080
echo "MK48 内部端口: $PORT"

# 设置 Rust 环境变量（防止 CA 证书错误）
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs
export RUST_LOG=info

echo "CA 证书: $SSL_CERT_FILE"

# 检查证书文件
if [ -f "$SSL_CERT_FILE" ]; then
    echo "✅ 系统 CA 证书正常"
else
    echo "❌ 系统 CA 证书缺失"
    exit 1
fi

# 检查可执行文件
[ -f "./mk48-plus-bin" ] || { echo "错误: 无 mk48-plus-bin"; exit 1; }
chmod +x ./mk48-plus-bin 2>/dev/null || true

# 创建必要目录
mkdir -p public
echo "OK" > public/health

# 启动命令（与原始相同）
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
