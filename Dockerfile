FROM alpine:latest

ARG CCM_VERSION=v0.6.1
ARG CCM_DOWNLOAD_URL=https://github.com/9j/claude-code-mux/releases/download/${CCM_VERSION}/ccm-linux-x86_64-musl.tar.gz

RUN apk add --no-cache curl ca-certificates && \
    curl -fsSL "${CCM_DOWNLOAD_URL}" | tar -xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/ccm && \
    rm -rf /var/cache/apk/*

RUN addgroup -g 1000 ccm && \
    adduser -D -u 1000 -G ccm ccm && \
    mkdir -p /config /data && \
    chown -R ccm:ccm /config /data

USER ccm
WORKDIR /app

ENV CCM_CONFIG_DIR=/config
ENV CCM_DATA_DIR=/data

EXPOSE 13456

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:13456/api/config/json || exit 1

ENTRYPOINT ["ccm"]
CMD ["--config", "/config/config.toml", "start"]
