FROM ubuntu:22.04

# 安装最小依赖
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    socat \
    && rm -rf /var/lib/apt/lists/*

# 更新 CA 证书
RUN update-ca-certificates

WORKDIR /app

# 复制文件
COPY mk48-linux-x64.tar.gz build.sh start.sh ./

# 构建
RUN chmod +x build.sh start.sh && ./build.sh

# 设置环境变量
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# 暴露端口
EXPOSE ${PORT}

# 直接使用 CMD：启动 MK48 + socat 代理
CMD sh -c "\
    echo '=== 启动服务 ===' && \
    echo '外部端口 (socat): '${PORT} && \
    echo '内部端口 (MK48): 8080' && \
    \
    # 启动 MK48（使用现有的 start.sh）\
    PORT=8080 /app/start.sh & \
    \
    # 等待 MK48 启动\
    sleep 5 && \
    \
    # 启动 socat 代理\
    echo '启动 socat 代理...' && \
    exec socat \
        TCP-LISTEN:${PORT},reuseaddr,fork \
        TCP:localhost:8080"
