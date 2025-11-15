#!/bin/bash
set -e

echo "=== 下载预编译的 trunk ==="
# 下载预编译的 trunk 二进制文件（避免从源码编译）
TRUNK_VERSION="0.21.14"
wget -q "https://github.com/thedodd/trunk/releases/download/v${TRUNK_VERSION}/trunk-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf trunk-x86_64-unknown-linux-gnu.tar.gz
chmod +x trunk
sudo mv trunk /usr/local/bin/

echo "=== 安装 Rust 基础环境 ==="
curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly --profile minimal
source "$HOME/.cargo/env"
rustup target add wasm32-unknown-unknown

echo "=== 构建客户端 ==="
cd client
trunk build --release --public-url "/"
