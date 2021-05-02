# FROM allinurl/goaccess
FROM alpinelinux/docker-cli

RUN apk add --no-cache goaccess

COPY logfeed.sh browsers.list /

VOLUME [ "/data" ]

ENTRYPOINT [ "/logfeed.sh" ]
