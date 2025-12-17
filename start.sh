#!/bin/bash
# start.sh - 正确版本
set -e

RENDER_PORT=${PORT:-1145}

# 使用 structopt 的正确参数
exec ./mk48-plus-bin \
    --http-port "$RENDER_PORT" \
    --debug-http info \
    --debug-game info \
    --debug-core info \
    --debug-sockets warn \
    --debug-watchdog info \
    --http-bandwidth-limit 100000 \
    --client-authenticate-burst 5 \
    --server-id 1


# 在 start.sh 中添加
echo "服务器将监听端口: $PORT"
./mk48-plus-bin --http-port "$PORT" --server-id 1 --debug-http debug &
sleep 2
curl -v http://localhost:$PORT/ 2>&1 | grep -i "listen\|connected\|failed"
