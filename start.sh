#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 ==="

# MK48 固定使用 8080 端口
PORT=8080
echo "MK48 内部端口: $PORT"

# 设置 CA 证书路径
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs

echo "CA 证书文件: $SSL_CERT_FILE"

# 检查可执行文件
[ -f "./mk48-plusbin" ] || { echo "错误: 无 mk48-plus-bin"; exit 1; }
chmod +x ./mk48-plus-bin 2>/dev/null || true

# 创建必要目录
mkdir -p public
echo "OK" > public/health

# 启动 MK48
exec ./mk48-plus-bin \
    --http-port "$PORT" \
    --server-id 1 \
    --debug-http info \
    --ip-address "0.0.0.0"
