#!/bin/bash
set -e

echo "=== 启动 MK48 HTTPS 服务器 ==="

# 硬编码端口 8443
HTTPS_PORT=8443
echo "内部 HTTPS 端口: $HTTPS_PORT"

# 必要检查
if [ ! -f "./mk48-plus-bin" ]; then
    echo "❌ 错误: 未找到 mk48-plus-bin"
    exit 1
fi
chmod +x ./mk48-plus-bin 2>/dev/null || true

# 证书路径
CERT_PATH="/app/certs/fullchain.pem"
KEY_PATH="/app/certs/privkey.pem"

if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo "❌ 证书文件缺失"
    ls -la /app/certs/ 2>/dev/null || echo "证书目录不存在"
    exit 1
fi

echo "✅ 找到证书文件"

# 启动 MK48
echo "启动命令: ./mk48-plus-bin --http-port $HTTPS_PORT --certificate-path $CERT_PATH --private-key-path $KEY_PATH --ip-address 0.0.0.0 --debug-http info"

exec ./mk48-plus-bin \
    --http-port "$HTTPS_PORT" \
    --certificate-path "$CERT_PATH" \
    --private-key-path "$KEY_PATH" \
    --ip-address "0.0.0.0" \
    --server-id 1 \
    --debug-http info \
    --debug-game warn \
    --http-bandwidth-limit 100000
