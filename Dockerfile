FROM ubuntu:22.04

# 安装必要依赖
RUN apt-get update && apt-get install -y \
    nginx \
    libssl3 \
    gettext-base \  # 包含 envsubst
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制文件
COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

# 构建应用
RUN chmod +x build.sh start.sh && \
    ./build.sh

# 创建 nginx 配置模板 - 简化版本
RUN echo 'events {}\n\
http {\n\
    server {\n\
        listen 10000;\n\
        \n\
        location = /healthz {\n\
            return 200 "OK";\n\
        }\n\
        \n\
        location / {\n\
            proxy_pass http://localhost:8080;\n\
            proxy_set_header X-Forwarded-Proto http;\n\
            proxy_redirect off;\n\
            proxy_http_version 1.1;\n\
            proxy_set_header Host \$host;\n\
        }\n\
    }\n\
}' > /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 10000

# 关键修复：使用 shell 格式的 CMD
CMD sh -c "\
    echo '=== 启动服务 ===' && \
    echo '启动 MK48 (端口 8080)...' && \
    PORT=8080 /app/start.sh & \
    sleep 5 && \
    echo '启动 nginx (端口 10000)...' && \
    exec nginx -g 'daemon off;'"
