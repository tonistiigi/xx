
# tonistiigi/xx:golang-riscv

FROM golang:alpine AS build
RUN apk add --no-cache gcc musl-dev bash git
WORKDIR /src

RUN git clone https://github.com/4a6f656c/riscv-go -b riscvdev-go1.13 --depth=1 go && \
  cd go/src && ./make.bash && \
  rm -rf go/pkg/bootstrap && \
  rm -rf go/pkg/obj

FROM alpine AS golang
RUN apk add --no-cache git
COPY --from=build /src/go /usr/local/go
RUN ln -s /usr/local/go/bin/go /usr/local/bin/go
COPY --from=tonistiigi/xx:golang / /

ENV GOPATH="/go"
ENV PATH="/go/bin:$PATH"
ENV CGO_ENABLED=0


