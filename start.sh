#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 ==="

# 1. 强制要求 PORT 变量存在
if [ -z "$PORT" ]; then
    echo "❌ 错误: PORT 环境变量未设置"
    echo "在 Render 上，PORT 由平台自动提供"
    exit 1
fi

echo "✅ 使用 Render 分配的端口: $PORT"

# 2. 设置环境变量
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# 如果还有 CA 证书错误，取消下面的注释
# export RUSTLS_UNVERIFIABLE_CERTIFICATES=1

# 3. 启动 MK48，必须监听 $PORT
exec ./mk48-plus-bin \
    --http-port "$PORT" \
    --ip-address "0.0.0.0" \
    --debug-http info
