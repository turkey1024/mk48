#!/bin/bash
set -e

echo "🔧 开始构建流程..."

# 启用详细日志
export RUST_LOG=info
export CARGO_TERM_COLOR=always

# 安装 Rust（如果未安装）
if ! command -v rustc &> /dev/null; then
    echo "📥 安装 Rust 工具链..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo "✅ Rust 版本: $(rustc --version)"
echo "✅ Cargo 版本: $(cargo --version)"

# 设置特定工具链
echo "🎯 设置 nightly-2024-04-20 工具链..."
rustup toolchain install nightly-2024-04-20 --profile minimal
rustup default nightly-2024-04-20
rustup target add wasm32-unknown-unknown

echo "✅ 工具链设置完成: $(rustc --version)"

# 安装 Trunk
if ! command -v trunk &> /dev/null; then
    echo "📥 安装 Trunk..."
    cargo install trunk --locked
fi

echo "✅ Trunk 版本: $(trunk --version)"

# 构建客户端（启用详细输出）
echo "🏗️ 开始构建客户端..."
cd client

echo "📁 当前目录: $(pwd)"
echo "📁 目录内容:"
ls -la

echo "📦 检查 Cargo.toml..."
if [ -f "Cargo.toml" ]; then
    cat Cargo.toml | head -20
else
    echo "❌ 错误: 找不到 Cargo.toml"
    exit 1
fi

# 先尝试 cargo check 来检查依赖问题
echo "🔍 检查依赖..."
cargo check --target wasm32-unknown-unknown --release || {
    echo "⚠️  cargo check 发现问题，继续尝试构建..."
}

# 使用详细模式构建
echo "🚀 开始 trunk build（详细模式）..."
RUST_BACKTRACE=1 trunk build --release -v

echo "🎉 构建完成！"
echo "📁 检查输出文件:"
if [ -d "dist" ]; then
    ls -la dist/
    echo "✅ 构建成功"
else
    echo "❌ 错误: 未生成 dist 目录"
    exit 1
fi
