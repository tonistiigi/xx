FROM scratch AS detect
COPY xx-detect /usr/bin/

FROM alpine AS test-alpine
RUN apk add --no-cache bats
COPY --from=detect / /
WORKDIR xx
COPY test-alpine.bats .
RUN ./test-alpine.bats

FROM detect