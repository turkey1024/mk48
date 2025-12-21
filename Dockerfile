FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

WORKDIR /app

COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

RUN chmod +x build.sh start.sh && \
    ./build.sh

# 关键修改：EXPOSE 一个具体的数字（如8080），或者完全去掉
# 方案A：写一个你应用常用的端口（仅作文档说明）
EXPOSE 8443

# 方案B：直接注释掉（Render 不依赖这个）
# EXPOSE

CMD ["./start.sh"]
