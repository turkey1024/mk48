FROM ubuntu:22.04

# 安装依赖
RUN apt-get update && apt-get install -y \
    nginx \
    libssl3 \
    ca-certificates \
    openssl \
    gettext-base \  # 包含 envsubst 命令
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制文件
COPY mk48-linux-x64.tar.gz build.sh start.sh ./

# 生成证书
RUN mkdir -p /app/certs && \
    openssl req -x509 -newkey rsa:2048 \
    -keyout /app/certs/privkey.pem \
    -out /app/certs/fullchain.pem \
    -days 365 -nodes \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MK48/CN=localhost" && \
    echo "✅ 证书生成完成"

# 构建 MK48
RUN chmod +x build.sh start.sh && \
    ./build.sh && \
    echo "✅ MK48 构建完成"

# 修改 start.sh 使用固定端口 8443
RUN sed -i 's/HTTPS_PORT=.*/HTTPS_PORT=8443/' start.sh 2>/dev/null || \
    echo "HTTPS_PORT=8443" >> start.sh

# nginx 配置模板
RUN echo 'events {}\n\
http {\n\
    server {\n\
        listen __PORT__;\n\
        server_name _;\n\
        \n\
        # 健康检查\n\
        location = /healthz {\n\
            add_header Content-Type text/plain;\n\
            return 200 "OK";\n\
            access_log off;\n\
        }\n\
        \n\
        # 代理所有请求到 MK48 HTTPS 服务\n\
        location / {\n\
            proxy_pass https://localhost:8443;\n\
            \n\
            # 关键：告诉 MK48 这是 HTTPS 请求\n\
            proxy_set_header X-Forwarded-Proto https;\n\
            proxy_set_header X-Forwarded-Ssl on;\n\
            \n\
            # 自签名证书，跳过验证\n\
            proxy_ssl_verify off;\n\
            proxy_ssl_session_reuse off;\n\
            \n\
            # 标准代理头\n\
            proxy_http_version 1.1;\n\
            proxy_set_header Host \$host;\n\
            proxy_set_header X-Real-IP \$remote_addr;\n\
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n\
            \n\
            # WebSocket 支持\n\
            proxy_set_header Upgrade \$http_upgrade;\n\
            proxy_set_header Connection "upgrade";\n\
            \n\
            # 超时设置\n\
            proxy_connect_timeout 60s;\n\
            proxy_send_timeout 60s;\n\
            proxy_read_timeout 300s;\n\
            \n\
            # 禁用缓冲，用于实时通信\n\
            proxy_buffering off;\n\
        }\n\
    }\n\
}' > /etc/nginx/nginx.conf.template

# 暴露端口
EXPOSE 10000

# 启动脚本 - 修复格式错误
CMD sh -c "\
    echo '=== 启动服务 ===' && \
    echo 'Render 端口: \${PORT}' && \
    \
    # 生成 nginx 配置（替换 __PORT__ 为实际值）\
    sed 's/__PORT__/'\${PORT:-10000}'/g' /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
    echo 'nginx 配置生成完成，监听端口: '\${PORT:-10000} && \
    \
    # 启动 MK48 HTTPS 服务\
    echo '启动 MK48 (端口 8443)...' && \
    /app/start.sh & \
    \
    # 等待 MK48 启动\
    echo '等待 MK48 启动...' && \
    sleep 8 && \
    \
    # 测试 MK48 是否就绪\
    if curl -k https://localhost:8443/healthz 2>/dev/null | grep -q OK; then \
        echo '✅ MK48 启动成功' && \
        echo '启动 nginx...' && \
        exec nginx -g 'daemon off;' \
    else \
        echo '❌ MK48 启动失败，检查日志' && \
        exit 1 \
    fi"

