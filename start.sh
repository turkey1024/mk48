#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 ==="

# 关键修改：完全使用Render传入的PORT，不要默认值8080
PORT=${PORT} # 去掉 :-8080 的默认值
if [ -z "${PORT}" ]; then
    echo "❌ 错误: PORT环境变量未设置"
    exit 1
fi
echo "监听端口: $PORT (由Render分配)"

export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

[ -f "./mk48-plus-bin" ] || { echo "错误: 无mk48-plus-bin"; exit 1; }

# 启动时，明确使用这个端口
exec ./mk48-plus-bin \
    --http-port "$PORT" \          # 关键：使用动态端口
    --ip-address "0.0.0.0" \
    --debug-http info
