# syntax = docker/dockerfile:1.2
from    koalaman/shellcheck-alpine:v0.7.2
workdir /src
copy base .
run shellcheck xx-*