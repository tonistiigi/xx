# syntax=docker/dockerfile-upstream:1.2.0-rc1

FROM alpine AS xx-apk
COPY detect/xx-detect apk/xx-apk apk/xx-clang-wrapper /usr/local/bin/

# RUN --mount=target=/ctx/xx-detect,src=detect/xx-detect \
#     --mount=target=/ctx/xx-apk,src=apk/xx-apk \
#     --mount=target=/ctx/clang_wrapper,src=apk/clang_wrapper \
#     mkdir -p /out/usr/local/bin && \
#     cp -a /ctx/xx-detect /out/usr/local/bin && \
#     cp -a /ctx/xx-apk /out/usr/local/bin && \
#     cp -a /ctx/clang_wrapper /out/usr/local/bin/clang && \
#     ln -s clang /out/usr/local/bin/clang++

    

FROM alpine AS dev
RUN apk add --no-cache vim
COPY --from=xx-apk / /
ENV XX_DEBUG_APK=1
ENTRYPOINT ["/bin/ash"]