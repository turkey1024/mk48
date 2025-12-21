FROM ubuntu:22.04

RUN apt-get update && apt-get install -y nginx openssl
RUN mkdir -p /app && mkdir -p /app/certs

WORKDIR /app

COPY mk48-linux-x64.tar.gz build.sh start.sh ./

RUN openssl req -x509 -newkey rsa:2048 \
    -keyout /app/certs/privkey.pem \
    -out /app/certs/fullchain.pem \
    -days 365 -nodes \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MK48/CN=localhost" 2>/dev/null

RUN chmod +x build.sh start.sh && ./build.sh

RUN echo 'events {}\nhttp {\nserver {\nlisten 10000;\nlocation / {\nproxy_pass https://localhost:8443;\nproxy_ssl_verify off;\n}\n}\n}' > /etc/nginx/nginx.conf

EXPOSE 10000

CMD /bin/bash -c "/app/start.sh & nginx -g 'daemon off;'"
