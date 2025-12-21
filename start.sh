#!/bin/bash
set -e

echo "=== 启动 MK48 HTTPS 服务器 ==="

# 硬编码端口
HTTPS_PORT=8443
echo "内部 HTTPS 端口: $HTTPS_PORT"

# 检查文件
if [ ! -f "./mk48-plus-bin" ]; then
    echo "错误: 无 mk48-plus-bin"
    exit 1
fi

# 证书检查
CERT_PATH="/app/certs/fullchain.pem"
KEY_PATH="/app/certs/privkey.pem"

if [ ! -f "$CERT_PATH" ]; then
    echo "错误: 无证书 $CERT_PATH"
    exit 1
fi

if [ ! -f "$KEY_PATH" ]; then
    echo "错误: 无私钥 $KEY_PATH"
    exit 1
fi

echo "找到证书文件"

# 创建健康检查文件
mkdir -p public
echo "OK" > public/healthz

# 启动
exec ./mk48-plus-bin \
    --http-port "$HTTPS_PORT" \
    --certificate-path "$CERT_PATH" \
    --private-key-path "$KEY_PATH" \
    --ip-address "0.0.0.0" \
    --server-id 1 \
    --debug-http info
