FROM rust:latest

# 安装依赖
RUN apt-get update && apt-get install -y make
RUN rustup toolchain install nightly
RUN rustup target add wasm32-unknown-unknown
RUN cargo install trunk

# 复制项目文件
WORKDIR /app
COPY . .

# 构建客户端
WORKDIR /app/client
RUN make release

# 设置输出目录
WORKDIR /app/client/dist
