#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 ==="

# 硬编码 HTTPS 端口
HTTPS_PORT=8443
echo "内部 HTTPS 端口: $HTTPS_PORT"

# 证书路径
CERT_PATH="/app/certs/fullchain.pem"
KEY_PATH="/app/certs/privkey.pem"

[ -f "./mk48-plus-bin" ] || { echo "错误: 无 mk48-plus-bin"; exit 1; }

# 启动 MK48 - 只处理 HTTPS
exec ./mk48-plus-bin \
    --http-port "$HTTPS_PORT" \
    --certificate-path "$CERT_PATH" \
    --private-key-path "$KEY_PATH" \
    --ip-address "0.0.0.0" \
    --debug-http info
