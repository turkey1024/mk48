#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 ==="
PORT=${PORT:-8080}
echo "端口: $PORT"

# 设置环境变量（解决 CA 证书问题）
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs
export RUST_BACKTRACE=1

# 检查可执行文件
[ -f "./mk48-plus-bin" ] || { echo "错误: 无 mk48-plus-bin"; exit 1; }
chmod +x ./mk48-plus-bin 2>/dev/null || true

# 关键：创建健康检查端点
mkdir -p public

# 1. /health - 纯文本 200 响应（Render 健康检查用）
cat > public/health << 'EOF'
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 2

OK
EOF

# 2. /healthz - JSON 格式的健康检查（常用标准）
cat > public/healthz << 'EOF'
{
  "status": "healthy",
  "service": "mk48",
  "timestamp": "2024-12-21T05:00:00Z",
  "version": "1.0"
}
EOF

# 3. 根路径 - 简单 HTML 页面
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>MK48 Game Server</title>
    <style>
        body { font-family: sans-serif; margin: 40px; line-height: 1.6; }
        h1 { color: #333; }
        .status { color: green; font-weight: bold; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🎮 MK48 Game Server</h1>
    <p>Status: <span class="status">RUNNING</span></p>
    <p>Health endpoints:</p>
    <ul>
        <li><a href="/health">/health</a> - Plain text (Render check)</li>
        <li><a href="/healthz">/healthz</a> - JSON format</li>
    </ul>
    <hr>
    <p><small>Connect via game client to play!</small></p>
</body>
</html>
EOF

echo "✅ 健康检查端点已创建:"
echo "   /health  - 纯文本 200 OK"
echo "   /healthz - JSON 格式"
echo "   /index.html - 状态页面"

# 启动 MK48
echo "🚀 启动 MK48 服务器..."
exec ./mk48-plus-bin \
    --http-port "$PORT" \
    --server-id 1 \
    --debug-http info \
    --debug-game warn \
    --debug-core error \
    --debug-sockets warn \
    --http-bandwidth-limit 100000 \
    --ip-address 0.0.0.0 \
    --client-authenticate-burst 10
