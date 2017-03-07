FROM ubuntu:xenial

ARG DEBIAN_FRONTEND=noninteractive
ARG TERM=linux

RUN apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
    apt-utils \
  && apt-get install --no-install-recommends --no-install-suggests -y \
    ca-certificates \
    curl \
    nginx-extras \
    gettext-base \
    telnet \
    vim \
  && rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

# config dirs
RUN mkdir -p \
  /etc/nginx/http.conf.d \
  /etc/nginx/stream.conf.d

COPY nginx.conf /etc/nginx/
COPY spark.conf zeppelin.conf /etc/nginx/http.conf.d/
COPY spark-stream.conf /etc/nginx/stream.conf.d/

WORKDIR /etc/nginx

EXPOSE 80 443 7077

CMD ["nginx", "-g", "daemon off;"]
