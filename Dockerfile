FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    nginx \
    libssl3 \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mk48-linux-x64.tar.gz build.sh start.sh ./

# 生成证书
RUN mkdir -p /app/certs && \
    openssl req -x509 -newkey rsa:2048 \
    -keyout /app/certs/privkey.pem \
    -out /app/certs/fullchain.pem \
    -days 365 -nodes \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MK48/CN=localhost"

# 构建 MK48
RUN chmod +x build.sh start.sh && ./build.sh

# 修改 start.sh 使用固定端口 8443
RUN sed -i 's/HTTPS_PORT=.*/HTTPS_PORT=8443/' start.sh

# nginx 配置：监听 Render 的 PORT，代理到 8443
RUN echo 'events {}\n\
http {\n\
    server {\n\
        listen ${PORT};\n\
        \n\
        location = /healthz {\n\
            return 200 "OK";\n\
        }\n\
        \n\
        location / {\n\
            proxy_pass https://localhost:8443;\n\
            \n\
            # 关键：告诉 MK48 这是 HTTPS 请求，避免重定向\n\
            proxy_set_header X-Forwarded-Proto https;\n\
            proxy_ssl_verify off;  # 因为自签名证书\n\
            \n\
            proxy_http_version 1.1;\n\
            proxy_set_header Host $host;\n\
        }\n\
    }\n\
}' > /etc/nginx/nginx.conf.template

EXPOSE ${PORT}

CMD ["sh", "-c", "\
    # 启动 MK48 (8443)\n\
    ./start.sh &\n\
    \n\
    # 生成 nginx 配置\n\
    envsubst '\${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf\n\
    \n\
    # 启动 nginx\n\
    nginx -g 'daemon off;'"]
