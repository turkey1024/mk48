FROM ubuntu:22.04

# 显示架构信息
RUN echo "容器架构: $(uname -m)"

# 安装依赖：包括 OpenSSL 用于生成证书
RUN apt-get update && apt-get install -y \
    libssl3 \
    ca-certificates \
    openssl \  # 关键：用于生成自签名证书
    file \
    binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制应用文件
COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

# 1. 创建证书目录
RUN mkdir -p /app/certs

# 2. 生成自签名证书 (在构建时完成，省去运行时步骤)
RUN openssl req -x509 -newkey rsa:2048 \
    -keyout /app/certs/privkey.pem \
    -out /app/certs/fullchain.pem \
    -days 365 \
    -nodes \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MK48 Server/CN=mk48.onrender.com" \
    2>/dev/null && \
    echo "自签名证书已生成"

# 3. 构建应用
RUN chmod +x build.sh start.sh && \
    ./build.sh

# 关键：设置默认端口为 HTTPS 的 8443
ENV PORT=8443

# 声明容器监听的端口（给 Render 看）
EXPOSE $PORT

# 启动应用
CMD ["./start.sh"]
