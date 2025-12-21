FROM ubuntu:22.04

# 关键：先安装 ca-certificates，这是原始能工作的配置
RUN apt-get update && apt-get install -y \
    ca-certificates \      # 修复 CA 证书问题
    libssl3 \
    nginx \                # 添加 nginx 解决重定向
    && rm -rf /var/lib/apt/lists/*

# 更新 CA 证书
RUN update-ca-certificates

WORKDIR /app

COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

RUN chmod +x build.sh start.sh && \
    ./build.sh

# 创建正确的 nginx 配置（简化但有效）
RUN echo 'events { worker_connections 1024; }\n\
http {\n\
    server {\n\
        listen 10000;\n\
        \n\
        # 健康检查直接由 nginx 处理\n\
        location = /health {\n\
            return 200 "OK";\n\
            add_header Content-Type text/plain;\n\
        }\n\
        \n\
        # 所有请求代理到 MK48\n\
        location / {\n\
            proxy_pass http://localhost:8080;\n\
            \n\
            # 关键：防止重定向循环\n\
            proxy_set_header X-Forwarded-Proto http;\n\
            proxy_redirect off;\n\
            \n\
            proxy_http_version 1.1;\n\
            proxy_set_header Host \$host;\n\
            \n\
            # WebSocket 支持\n\
            proxy_set_header Upgrade \$http_upgrade;\n\
            proxy_set_header Connection "upgrade";\n\
        }\n\
    }\n\
}' > /etc/nginx/nginx.conf

# 暴露 nginx 端口（Render 会使用 10000）
EXPOSE 10000

# 设置 Rust 环境变量
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_DIR=/etc/ssl/certs

# 简单启动：先 MK48，后 nginx
CMD /app/start.sh & nginx -g 'daemon off;'
