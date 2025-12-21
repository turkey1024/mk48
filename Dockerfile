FROM ubuntu:22.04

# 显示架构信息
RUN echo "容器架构: $(uname -m)"

# 安装依赖（修复：file 应该是小写）
RUN apt-get update && apt-get install -y \
    libssl3 \
    ca-certificates \
    openssl \
    file \          # 修复：改为小写
    binutils \
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
    2>/dev/null && \
    echo "✅ 自签名证书已生成"

# 显示证书信息（用于调试）
RUN ls -la /app/certs/ && \
    openssl x509 -in /app/certs/fullchain.pem -text -noout 2>/dev/null | head -5

# 构建应用
RUN chmod +x build.sh start.sh && \
    ./build.sh

# 检查构建结果
RUN ls -la && \
    [ -f "./mk48-plus-bin" ] && echo "✅ mk48-plus-bin 存在" || echo "❌ mk48-plus-bin 不存在"

# 设置默认端口为 HTTPS 的 8443
ENV PORT=8443

# 声明容器监听的端口
EXPOSE $PORT

# 启动应用
CMD ["./start.sh"]
