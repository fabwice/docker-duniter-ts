# Image for Duniter releases on Linux.
#
# Building this image:
#   docker build . -t duniter/duniter-ts
#
# TODO: npm install sqlite3@3.1.11 is required since previous versions have a
# bug for compiling with MuslC. Remove the line when it becomes useless.

# First stage, application building
FROM fabwice/docker-alpine-node:8.14.0 AS dun-compile

ARG DUNITER_VERSION=1.7.19
ARG UI_VERSION=1.7.x

RUN apk update && \
	apk add ca-certificates wget && \
	update-ca-certificates

RUN mkdir /duniter && cd /duniter && \
	wget https://git.duniter.org/nodes/typescript/duniter/repository/v${DUNITER_VERSION}/archive.tar.gz && \
	tar -xzf archive.tar.gz && rm *.tar.gz && mv duniter-* duniter-ts && \
	apk add --update python make g++ && \
	cd /duniter/duniter-ts && \
	yarn add sqlite3@3.1.11 && \
	yarn install --production && yarn add duniter-ui@${UI_VERSION} && \
	rm -rf test/ && find . -name '*.ts' -exec rm "{}" +

# Second stage
FROM fabwice/docker-alpine-node:8.14.0

RUN addgroup -S -g 1111 duniter && \
	adduser -SD -h /duniter -G duniter -u 1111 duniter
RUN mkdir -p /var/lib/duniter /etc/duniter && chown duniter:duniter /var/lib/duniter /etc/duniter
COPY --from=dun-compile --chown=duniter:duniter /duniter/duniter-ts /duniter/duniter-ts

VOLUME /var/lib/duniter
VOLUME /etc/duniter
EXPOSE 9220 10901 20901

USER duniter
WORKDIR /duniter
COPY duniter.sh /usr/bin/duniter
ENTRYPOINT ["/usr/bin/duniter"]
CMD []
