ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

WORKDIR /repo

RUN apt-get update && apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -L "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.$(uname -m)" -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

ENTRYPOINT ["/bin/bash", "-c"]

CMD ["cd /tmp && \
    ttyd \
    --url-arg \
    --writable \
    --interface /repo/terminal.sock \
    /bin/bash"]