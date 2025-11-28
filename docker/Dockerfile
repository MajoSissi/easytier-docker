FROM alpine:latest AS builder

ARG VERSION
ARG TARGETARCH
ARG TARGETVARIANT

COPY scripts/download.sh /download.sh
RUN apk add --no-cache curl unzip && \
    chmod +x /download.sh && \
    /download.sh "$VERSION" "$TARGETARCH" "$TARGETVARIANT" && \
    rm -f /usr/local/bin/easytier-web

FROM alpine:latest

RUN apk add --no-cache tzdata tini bash ca-certificates gcompat libgcc libstdc++

COPY --from=builder /usr/local/bin/ /usr/local/bin/

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create config directory and web directory
RUN mkdir -p /web/logs

VOLUME /web

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD [""]
