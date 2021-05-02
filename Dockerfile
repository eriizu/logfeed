# FROM allinurl/goaccess
FROM alpinelinux/docker-cli

RUN apk add --no-cache goaccess

COPY logfeed.sh /logfeed.sh

VOLUME [ "/data" ]

ENTRYPOINT [ "/logfeed.sh" ]
