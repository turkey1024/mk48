#!/bin/bash
# start.sh - 正确版本
set -e

RENDER_PORT=${PORT:-1145}


# 在 start.sh 中添加
echo "服务器将监听端口: $PORT"
./mk48-plus-bin --http-port "$PORT" --server-id 1 --debug-http debug &
sleep 2
curl -v http://localhost:$PORT/ 2>&1 | grep -i "listen\|connected\|failed"
