FROM alpine:3.20

LABEL org.opencontainers.image.title="stop2shell" \
      org.opencontainers.image.description="CVE-2026-73737373 (7350pipe#reborn) proof of concept" \
      org.opencontainers.image.licenses="Unlicense"

RUN apk add --no-cache bash coreutils

COPY stop2shell.sh /usr/local/bin/stop2shell
RUN chmod 0755 /usr/local/bin/stop2shell

ENTRYPOINT ["stop2shell"]
