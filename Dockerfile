FROM ubuntu:22.04

# 显示架构信息
RUN echo "容器架构: $(uname -m)"

# 安装依赖 - 移除了不存在的 binutils
RUN apt-get update && apt-get install -y \
    libssl3 \
    ca-certificates \
    openssl \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制应用文件
COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

# 创建证书目录
RUN mkdir -p /app/certs

# 生成自签名证书
RUN openssl req -x509 -newkey rsa:2048 \
    -keyout /app/certs/privkey.pem \
    -out /app/certs/fullchain.pem \
    -days 365 \
    -nodes \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MK48 Server/CN=mk48.onrender.com" \
    2>/dev/null

# 显示证书信息
RUN echo "✅ 证书生成成功" && \
    ls -la /app/certs/

# 构建应用
RUN chmod +x build.sh start.sh && \
    ./build.sh

# 检查构建结果
RUN echo "检查构建结果:" && \
    ls -la && \
    [ -f "./mk48-plus-bin" ] && echo "✅ mk48-plus-bin 存在" || (echo "❌ mk48-plus-bin 不存在" && exit 1)

# 设置默认端口为 HTTPS 的 8443
ENV PORT=8443

# 声明容器监听的端口
EXPOSE $PORT

# 启动应用
CMD ["./start.sh"]
