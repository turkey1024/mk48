#!/bin/bash
set -e

echo "=== 开始安装 Rust ==="
curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly --profile minimal
source "$HOME/.cargo/env"

echo "=== 设置 Rust 工具链 ==="
rustup default nightly
rustup target add wasm32-unknown-unknown

echo "=== 安装 Trunk ==="
cargo install trunk --locked

echo "=== 构建客户端 ==="
cd client
trunk build --release --public-url "/"
