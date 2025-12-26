#!/bin/bash
set -e

echo "=== 启动 MK48 服务器 ==="

export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

exec ./mk48-plus-bin \
    --http-port 80 \
    --max-bots 0 \
    --http-bandwidth-limit 1000000 \
    --http-bandwidth-burst 1000000 \
    --certificate-path cert.pem \
    --private-key-path key.pem \
    --debug-http info
