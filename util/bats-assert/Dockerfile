FROM --platform=$BUILDPLATFORM alpine AS build
RUN apk add --no-cache git
WORKDIR /work
RUN git clone --bare git://github.com/ztombol/bats-support && \
    mkdir -p /out/bats-support && cd /out/bats-support && \
    git --git-dir=/work/bats-support.git --work-tree=. checkout 004e707638eedd62e0481e8cdc9223ad471f12ee -- src load.bash LICENSE

RUN git clone --bare git://github.com/ztombol/bats-assert && \
    mkdir -p /out/bats-assert && cd /out/bats-assert && \
    git --git-dir=/work/bats-assert.git --work-tree=. checkout 9f88b4207da750093baabc4e3f41bf68f0dd3630 -- src load.bash LICENSE

RUN echo 'source "$(dirname "${BASH_SOURCE[0]}")/bats-support/load.bash"' > /out/assert.bash && \
    echo 'source "$(dirname "${BASH_SOURCE[0]}")/bats-assert/load.bash"' >> /out/assert.bash


FROM scratch AS release
COPY --from=build /out /

FROM alpine AS test-gen
RUN apk add --no-cache bats
WORKDIR /work
COPY --from=release . .
COPY test.bats .
RUN bats ./test.bats &> test.bats.output || true

FROM test-gen AS test
COPY test.bats.golden .
RUN diff test.bats.output test.bats.golden

FROM scratch AS golden
COPY --from=test-gen /work/test.bats.output test.bats.golden

FROM release