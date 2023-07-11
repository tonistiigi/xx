ARG OSXCROSS_VERSION=12.3

# Make sure to read XCode license agreement before using this code
# same for all arch therefore hardcoded to arm64
FROM --platform=darwin/arm64 crazymax/osxcross:${OSXCROSS_VERSION} AS osxcross

FROM scratch AS sdk-extras-darwin
COPY --from=osxcross /osxsdk /xx-sdk/

# this dance is a hack to work aroung windows tarball being different from linux
# create directories in both levels so layers can be accessed from either OS
FROM --platform=$BUILDPLATFORM alpine AS extras-base
RUN mkdir -p /out/Files/xx-sdk /out/xx-sdk

FROM scratch AS sdk-extras-linux
COPY --from=extras-base /out/Files /xx-sdk

FROM scratch AS sdk-extras-windows
COPY --from=extras-base /out /

FROM sdk-extras-linux AS sdk-extras-freebsd

FROM sdk-extras-${TARGETOS} AS sdk-extras
