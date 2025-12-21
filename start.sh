#!/bin/bash
set -e

echo "=== 启动 MK48 HTTPS 服务器 ==="

# 使用 Render 分配的端口
PORT=${PORT:-8443}
echo "HTTPS 端口: $PORT"

# 证书路径
CERT_PATH="/app/certs/fullchain.pem"
KEY_PATH="/app/certs/privkey.pem"

echo "证书路径: $CERT_PATH"
echo "私钥路径: $KEY_PATH"

# 检查证书是否存在
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo "❌ 错误: 证书文件缺失"
    echo "当前证书目录内容:"
    ls -la /app/certs/ 2>/dev/null || echo "证书目录不存在"
    exit 1
fi

echo "✅ 证书文件正常"

# 显示证书信息
echo "🔐 证书主题:"
openssl x509 -in "$CERT_PATH" -noout -subject 2>/dev/null || echo "无法读取证书"

# 检查可执行文件
if [ ! -f "./mk48-plus-bin" ]; then
    echo "❌ 错误: 未找到 mk48-plus-bin"
    exit 1
fi
chmod +x ./mk48-plus-bin 2>/dev/null || true

# 创建必要的目录（如果不存在）
mkdir -p public
if [ ! -f "public/index.html" ]; then
    echo '<!DOCTYPE html><html><head><title>MK48 HTTPS Server</title></head><body><h1>MK48 Game Server</h1><p>Running with HTTPS</p></body></html>' > public/index.html
fi

# 创建健康检查端点
echo "OK" > public/health

echo "🚀 启动命令:"
echo "./mk48-plus-bin --http-port $PORT --certificate-path $CERT_PATH --private-key-path $KEY_PATH --ip-address 0.0.0.0 --debug-http info"

# 启动 MK48 HTTPS 服务
exec ./mk48-plus-bin \
    --http-port "$PORT" \
    --certificate-path "$CERT_PATH" \
    --private-key-path "$KEY_PATH" \
    --ip-address "0.0.0.0" \
    --server-id 1 \
    --debug-http info \
    --debug-game warn \
    --http-bandwidth-limit 100000
