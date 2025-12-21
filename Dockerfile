FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    nginx \
    && rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

WORKDIR /app

COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

RUN chmod +x build.sh start.sh && \
    ./build.sh

# 创建启动脚本，动态使用 $PORT
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "=== 启动服务 ==="\n\
echo "Render 分配的端口: ${PORT}"\n\
\n\
# 检查 PORT 是否设置\n\
if [ -z "${PORT}" ]; then\n\
    echo "错误: PORT 环境变量未设置"\n\
    exit 1\n\
fi\n\
\n\
# 1. 启动 MK48 (固定端口 8080)\n\
echo "启动 MK48 (端口 8080)..."\n\
PORT=8080 /app/start.sh &\n\
MK48_PID=$!\n\
\n\
# 等待 MK48 启动\n\
sleep 5\n\
\n\
# 检查 MK48 是否运行\n\
if ! kill -0 $MK48_PID 2>/dev/null; then\n\
    echo "MK48 启动失败"\n\
    exit 1\n\
fi\n\
\n\
# 2. 创建 nginx 配置，使用 Render 的 PORT\n\
echo "创建 nginx 配置，监听端口: ${PORT}"\n\
cat > /etc/nginx/nginx.conf << "EOF"\nevents {\n\
    worker_connections 1024;\n\
}\n\
http {\n\
    server {\n\
        listen ${PORT};\n\
        \n\
        location = /health {\n\
            return 200 "OK";\n\
            add_header Content-Type text/plain;\n\
        }\n\
        \n\
        location / {\n\
            proxy_pass http://localhost:8080;\n\
            proxy_set_header X-Forwarded-Proto http;\n\
            proxy_redirect off;\n\
            proxy_http_version 1.1;\n\
            proxy_set_header Host $host;\n\
            proxy_set_header X-Real-IP $remote_addr;\n\
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
            \n\
            proxy_set_header Upgrade $http_upgrade;\n\
            proxy_set_header Connection "upgrade";\n\
        }\n\
    }\n\
}\nEOF\n\
\n\
# 替换 PORT 变量\n\
sed -i "s/\\\${PORT}/${PORT}/g" /etc/nginx/nginx.conf\n\
\n\
# 3. 启动 nginx\n\
echo "启动 nginx..."\n\
exec nginx -g "daemon off;"' > /app/launch.sh

RUN chmod +x /app/launch.sh

# 声明端口（Render 会检查这个）
EXPOSE ${PORT}

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# 使用启动脚本
CMD ["/app/launch.sh"]
