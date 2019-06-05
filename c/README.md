## c/cpp

Set gcc/g++ target platform the same as the build target platform.

```
FROM --platform=$BUILDPLATFORM tonistiigi/xx:c

ARG TARGETPLATFORM
RUN $(CC) main.c
```

Inside build you can call `target-linux-gnu` to return the correct target platform if requested by tooling.

`tonistiigi/xx:gcc-sid` image is similar but based on Debian sid and also supports RISC-V .

### Example with bash:

```
FROM --platform=$BUILDPLATFORM tonistiigi/xx:c AS builder
RUN apt-get install -y wget
WORKDIR /src
RUN wget https://github.com/bminor/bash/archive/bash-5.0.tar.gz && \
    tar xvf bash-5.0.tar.gz --strip-components=1
ARG TARGETPLATFORM
# dynamic:
# RUN ./configure --host=$(target-linux-gnu) && make
# static:
RUN ./configure --enable-static-link --without-bash-malloc --host=$(target-linux-gnu) && make

FROM scratch
COPY --from=builder /src/bash /
CMD ["/bash"]
```