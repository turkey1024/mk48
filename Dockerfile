FROM ubuntu:22.04

RUN echo "容器架构: $(uname -m)"


RUN apt-get update && apt-get install -y \
    libssl3 \
    ca-certificates \
    file \
    binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mk48-linux-x64.tar.gz .
COPY build.sh .
COPY start.sh .

RUN chmod +x build.sh start.sh && \
    ./build.sh


ENV PORT=8443
EXPOSE $PORT

CMD ["./start.sh"]
