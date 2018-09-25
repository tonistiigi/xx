#### golang

Set go compiler's target platform the same as the build target platform.

Expects to be copied over a `library/golang` image that has `/go/bin` as highest priority path component.

```
FROM --platform=$BUILDPLATFORM golang:1.11-alpine
COPY --from=tonistiigi/xx:golang / /

ARG TARGETPLATFORM
RUN go env
```