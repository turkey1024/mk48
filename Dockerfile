FROM ubuntu:22.04

# 安装必要依赖
RUN apt-get update && apt-get install -y \
    nginx \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制文件
COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

# 构建应用
RUN chmod +x build.sh start.sh && \
    ./build.sh

# 创建 nginx 配置 - 修复重定向循环的关键
RUN echo 'events {\n\
    worker_connections 1024;\n\
}\n\
http {\n\
    # 禁用 nginx 版本号显示\n\
    server_tokens off;\n\
    \n\
    server {\n\
        # 监听 Render 分配的端口\n\
        listen ${NGINX_PORT};\n\
        \n\
        # 强制设置所有请求为 HTTP 协议\n\
        set $forwarded_proto "http";\n\
        \n\
        # 健康检查端点 - 直接由 nginx 处理\n\
        location = /healthz {\n\
            add_header Content-Type text/plain;\n\
            return 200 "OK";\n\
            access_log off;\n\
        }\n\
        \n\
        # 静态文件服务（如果存在）\n\
        location ~ ^/(public/|static/|assets/) {\n\
            root /app;\n\
            try_files \$uri =404;\n\
        }\n\
        \n\
        # 代理所有其他请求到 MK48\n\
        location / {\n\
            # MK48 运行在 8080 端口（HTTP）\n\
            proxy_pass http://localhost:8080;\n\
            \n\
            # 关键修复：防止 MK48 重定向到 HTTPS\n\
            # 强制告诉 MK48 这是 HTTP 请求\n\
            proxy_set_header X-Forwarded-Proto \$forwarded_proto;\n\
            \n\
            # 移除任何可能的重定向头\n\
            proxy_redirect off;\n\
            \n\
            # 拦截 301/302 响应，改为 200\n\
            proxy_intercept_errors on;\n\
            error_page 301 302 =200 @no_redirect;\n\
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
            # 禁用缓冲\n\
            proxy_buffering off;\n\
        }\n\
        \n\
        # 当拦截到重定向时，返回静态页面\n\
        location @no_redirect {\n\
            add_header Content-Type text/html;\n\
            return 200 '\''<!DOCTYPE html><html><head><title>MK48 Server</title><style>body{font-family:sans-serif;margin:40px;background:#f5f5f5;}</style></head><body><h1>🎮 MK48 Game Server</h1><p>Server is running (via nginx proxy)</p></body></html>'\'';\n\
        }\n\
    }\n\
}' > /etc/nginx/nginx.conf.template

# 暴露端口
EXPOSE ${NGINX_PORT}

# 启动脚本
CMD ["/bin/bash", "-c", "\
    echo '=== 启动服务 ===';\
    echo 'Render 端口: '${PORT:-10000};\
    \
    # 设置 nginx 监听端口\
    export NGINX_PORT=${PORT:-10000};\
    \
    # 生成 nginx 配置\
    envsubst '\${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf;\
    echo 'nginx 配置生成完成，监听端口: '\$NGINX_PORT;\
    \
    # 启动 MK48（HTTP 8080）\
    echo '启动 MK48 (端口 8080)...';\
    PORT=8080 /app/start.sh &\
    \
    # 等待 MK48 启动\
    sleep 5;\
    \
    # 测试 MK48 是否就绪\
    if curl -s http://localhost:8080/ > /dev/null 2>&1; then\
        echo '✅ MK48 启动成功';\
        echo '启动 nginx 代理...';\
        nginx -g 'daemon off;';\
    else\
        echo '❌ MK48 启动失败';\
        exit 1;\
    fi"]
