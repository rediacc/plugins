ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}
LABEL com.rediacc.base-image="${BASE_IMAGE}"

WORKDIR /repo

RUN apt-get update && apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# Environment variables for socket configuration
ENV SOCKET_DIR=/sockets
ENV PLUGIN_NAME=Browser

ENTRYPOINT ["/bin/bash", "-c"]

CMD ["cd /tmp && \
    filebrowser \
    --disable-exec \
    --disable-preview-resize \
    --disable-thumbnails \
    --disable-type-detection-by-header \
    --noauth \
    --root /repo \
    --socket ${SOCKET_DIR}/${PLUGIN_NAME}.sock \
    --socket-perm 384"]