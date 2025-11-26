FROM alpine:latest

ARG VERSION
ARG TARGETARCH
ARG TARGETVARIANT

RUN apk add --no-cache tzdata tini bash curl unzip ca-certificates gcompat libgcc libstdc++ iproute2

COPY scripts/download.sh /download.sh
RUN chmod +x /download.sh && /download.sh "$VERSION" "$TARGETARCH" "$TARGETVARIANT"

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create config directory and web directory
RUN mkdir -p /web/logs

# Expose ports
# TCP/UDP 11010 (Core)
EXPOSE 11010
# Web ports
EXPOSE 11210
EXPOSE 11211
EXPOSE 22020

VOLUME /web

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD [""]
