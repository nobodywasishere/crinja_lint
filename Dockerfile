FROM alpine:edge AS builder
RUN apk add --update crystal shards yaml-dev musl-dev make libxml2-dev
RUN mkdir /crinja_lint
WORKDIR /crinja_lint
COPY . /crinja_lint/
RUN make clean && make

FROM alpine:latest
RUN apk add --update yaml pcre2 gc libevent libgcc libxml2
RUN mkdir /src
WORKDIR /src
COPY --from=builder /crinja_lint/bin/crinja_lint /usr/bin/
RUN crinja_lint -v
ENTRYPOINT [ "/usr/bin/crinja_lint" ]
