FROM ubuntu:22.04
RUN apt update && apt install -y ca-certificates
RUN update-ca-certificates
WORKDIR /app
COPY mk48-linux-x64.tar.gz build.sh start.sh ./
RUN chmod +x build.sh start.sh && ./build.sh
# 关键：不在Dockerfile中覆盖PORT
EXPOSE ${PORT} # 声明会使用动态端口
CMD ["./start.sh"]
