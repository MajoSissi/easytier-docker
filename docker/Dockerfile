FROM alpine:latest

ARG VERSION
ARG TARGETARCH
ARG TARGETVARIANT

RUN apk add --no-cache tzdata tini bash ca-certificates gcompat libgcc libstdc++

COPY scripts/download.sh /download.sh
RUN apk add --no-cache --virtual .dl-deps curl unzip && \
    chmod +x /download.sh && \
    /download.sh "$VERSION" "$TARGETARCH" "$TARGETVARIANT" && \
    rm -f /download.sh /usr/local/bin/easytier-web && \
    apk del .dl-deps

COPY --chmod=755 scripts/run.sh /run.sh

# Create config directory and web directory
RUN mkdir -p /web/logs /config

VOLUME /web /config

ENTRYPOINT ["/sbin/tini", "--", "/run.sh"]
