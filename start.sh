#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 (HTTPS 模式) ==="

# 使用 Dockerfile 中设置的 PORT 环境变量，应为 8443
HTTPS_PORT=${PORT:-8443}
echo "🛡️  HTTPS 服务端口: $HTTPS_PORT"

# 必要检查：可执行文件
if [ ! -f "./mk48-plus-bin" ]; then
    echo "❌ 错误: 未找到 mk48-plus-bin 可执行文件"
    exit 1
fi
chmod +x ./mk48-plus-bin 2>/dev/null || true

# 关键：证书路径 (与 Dockerfile 中生成的位置一致)
CERT_PATH="/app/certs/fullchain.pem"
KEY_PATH="/app/certs/privkey.pem"

# 严格检查证书是否存在
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo "❌ 致命错误: 未找到 SSL 证书文件。"
    echo "   证书路径: $CERT_PATH"
    echo "   私钥路径: $KEY_PATH"
    exit 1
fi
echo "✅ 找到 SSL 证书，启用 HTTPS"

# 前端目录检查
if [ ! -d "public" ]; then
    mkdir -p public
    echo '<!DOCTYPE html><html><head><title>MK48 HTTPS Server</title></head><body><h1>MK48 Game Server</h1><p>🔐 Running in secure HTTPS mode</p></body></html>' > public/index.html
    echo "⚠️  创建了简易 public/index.html"
fi

# 创建健康检查端点 (Render 需要)
if [ ! -f "public/healthz" ]; then
    echo "OK" > public/healthz
    echo "✅ 创建健康检查端点: /healthz"
fi

echo "🚀 启动参数摘要:"
echo "   --http-port: $HTTPS_PORT"
echo "   --certificate-path: $CERT_PATH"
echo "   --private-key-path: $KEY_PATH"
echo "   --ip-address: 0.0.0.0"

# 启动 MK48 服务器
# 注意：我们只提供 HTTPS 相关参数，不涉及 HTTP 8080
exec ./mk48-plus-bin \
    --http-port "$HTTPS_PORT" \
    --certificate-path "$CERT_PATH" \
    --private-key-path "$KEY_PATH" \
    --ip-address "0.0.0.0" \
    --server-id 1 \
    --debug-http info \
    --debug-game info \
    --debug-core error \
    --debug-sockets warn \
    --http-bandwidth-limit 100000 \
    --client-authenticate-burst 10
