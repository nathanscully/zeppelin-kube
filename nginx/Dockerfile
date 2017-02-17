FROM nginx:latest

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Install apt-utils to configure packages later,
# tools for debugging and dependencies
RUN	apt-get update \
    && apt-get install -y --no-install-recommends \
      apt-utils \
    && apt-get install -y --no-install-recommends \
      curl \
      telnet \
      vim \
    && rm -r /var/lib/apt/lists/*
    # && rm /etc/nginx/conf.d/*.conf

WORKDIR /etc/nginx

COPY zeppelin.oneflare.io.conf /etc/nginx/conf.d/
COPY allowed-ips.conf /etc/nginx/
