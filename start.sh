#!/bin/bash
# start.sh - 正确版本
set -e

RENDER_PORT=${PORT:-8080}

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

