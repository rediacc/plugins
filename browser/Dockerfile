ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}
ARG BASE_IMAGE
LABEL com.rediacc.base-image="${BASE_IMAGE}"

WORKDIR /repo

RUN apt-get update && apt-get install -y curl tar && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install filebrowser manually
# NOTE: The official install script (https://raw.githubusercontent.com/filebrowser/get/master/get.sh)
# was broken as of 2025-11-06 (generates invalid URLs with double slashes).
# If the script is fixed upstream, this can be replaced with:
#   curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
# Manual installation ensures reliable builds:
RUN FILEBROWSER_VERSION=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/') && \
    curl -fsSL "https://github.com/filebrowser/filebrowser/releases/download/v${FILEBROWSER_VERSION}/linux-amd64-filebrowser.tar.gz" | tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/filebrowser

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