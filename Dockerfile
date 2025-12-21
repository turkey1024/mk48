FROM ubuntu:22.04

# 安装依赖
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# 更新系统 CA 证书（解决 Rust 的 no CA certificates found 错误）
RUN update-ca-certificates

WORKDIR /app

# 复制文件
COPY mk48-linux-x64.tar.gz build.sh start.sh ./

# 构建应用
RUN chmod +x build.sh start.sh && \
    ./build.sh

# 创建证书目录
RUN mkdir -p /app/certs

# 生成自签名证书（关键步骤）
RUN openssl req -x509 -newkey rsa:2048 \
    -keyout /app/certs/privkey.pem \
    -out /app/certs/fullchain.pem \
    -days 365 \
    -nodes \
    -subj "/C=US/ST=California/L=San Francisco/O=MK48/CN=turkey-mk.onrender.com" \
    2>/dev/null

# 验证证书生成
RUN echo "证书生成完成:" && \
    ls -la /app/certs/ && \
    echo "证书信息:" && \
    openssl x509 -in /app/certs/fullchain.pem -noout -subject -dates 2>/dev/null

# 设置 Rust 环境变量（重要）
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV RUST_BACKTRACE=1

# 暴露端口 - MK48 将直接提供 HTTPS
EXPOSE ${PORT}

CMD ["./start.sh"]
