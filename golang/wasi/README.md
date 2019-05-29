wasi support for golang is in very early stages. Do not expect anything but hello-world to work.

Porting is happening in https://github.com/neelance/go/tree/wasi .

```
FROM --platform=$BUILDPLATFORM tonistiigi/xx:golang-wasm AS build
WORKDIR /src
COPY main.go .
ARG TARGETPLATFORM
ENV CGO_ENABLED=0
RUN go build -o /gohello main.go

FROM scratch
COPY --from=build /gohello /
ENTRYPOINT ["/gohello"]
```