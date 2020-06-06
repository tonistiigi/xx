FROM --platform=$BUILDPLATFORM golang:alpine AS test

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM}, building for ${TARGETPLATFORM}\n$(uname -a)\n"

COPY wrapper.sh /go/bin/go
RUN go env

FROM scratch
COPY --from=test /go/bin/go /go/bin/go