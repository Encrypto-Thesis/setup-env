FROM --platform=amd64 fedora:38

RUN dnf install -y \
    asio-devel \
    # libsodium \
    cmake \
    git \
    gmp \
    gcc \
    gcc-c++ \
    openssl-libs \
    openssl-devel \
    openssl \
    boost-static \
    libsodium-static \
    libdivide-devel \
    gmp-c++    \
    gmp-devel
    # gmp-static

ARG MY_UID=1000
ARG MY_GID=1000
ARG MY_USER=user

RUN groupadd --gid ${MY_GID} ${MY_USER} \
    && useradd  --create-home --gid ${MY_GID} --uid ${MY_UID} --home /home/${MY_USER} ${MY_USER} \
    && echo "${MY_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# ENV CXX=g++-12

# FROM --platform=amd64 alpine:latest

# ARG MY_UID=1000
# ARG MY_GID=1000
# ARG MY_USER=user

# RUN apk add --no-cache boost-dev boost1.82-static gcc git cmake g++ gmp-dev gmp libsodium libsodium-dev libsodium-static libssl3 sudo make openssl openssl-libs-static openssl-dev
# RUN mkdir -p /home/${MY_USER} \
#     && echo "${MY_USER}:x:${MY_GID}:" >> /etc/group \
#     && echo "${MY_USER}:x:${MY_UID}:${MY_GID}:${MY_USER}:/home/${MY_USER}:/bin/ash" >> /etc/passwd \
#     && chown -R ${MY_USER}:${MY_GID} /home/${MY_USER} \
#     && echo "${MY_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# ENV CXX=g++

