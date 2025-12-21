# 最小化 Dockerfile
FROM ubuntu:22.04

# 只安装绝对必要的
RUN apt update && apt install -y nginx

WORKDIR /app

# 复制文件
COPY mk48-linux-x64.tar.gz build.sh start.sh ./

# 构建
RUN chmod +x build.sh start.sh
RUN ./build.sh

# 极简 nginx 配置
RUN echo 'events{} http{server{listen 10000;location/{proxy_pass http://localhost:8080;}}}' > /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 10000

# 最简单启动
CMD /app/start.sh & nginx -g 'daemon off;'
