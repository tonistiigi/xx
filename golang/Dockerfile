FROM --platform=$BUILDPLATFORM golang:alpine AS test

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM}, building for ${TARGETPLATFORM}\n$(uname -a)\n"

COPY cross-env.sh /usr/sbin/cross-go-env
COPY wrapper.sh /go/bin/go
RUN go env

FROM scratch
COPY --from=test /usr/sbin/cross-go-env /usr/sbin/cross-go-env
COPY --from=test /go/bin/go /go/bin/go
