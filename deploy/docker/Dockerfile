# The contents of this file are covered by APACHE License Version 2.
# See licenses/APACHEV2-LICENSE.txt for more information.

# Base build environment
#
# Note: This image contains both the dependencies needed for building dependent images and
# also the dependencies required by build actions to be in their environment.

FROM ubuntu:20.04 AS build_env

# Install dependencies for building dependent images.
RUN apt-get update && apt-get install -y build-essential libyaml-dev

# Install build action dependencies.
# - Python 3 is used by the Pants client support.
RUN apt-get install -y python3 python3-distutils tar unzip
# - Python -> Python3 symlink needed for GOMA and BuildFarm
RUN ln -s /usr/bin/python3 /usr/bin/python

# Goma client

FROM build_env as goma_client

ARG GOMA_CLIENT_GIT_SHA

RUN apt-get update && apt-get install -y git wget python3

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools
WORKDIR depot_tools
RUN ./cipd install infra/goma/client/linux-amd64  	git_revision:$GOMA_CLIENT_GIT_SHA -root ../goma

RUN apt-get install -y lsof

RUN useradd -m goma --uid=1000
USER goma
WORKDIR /tmp

# Goma server

FROM golang:1.14.7 as goma_server

ARG GOMA_SERVER_VERSION

COPY goma_server_patches.patch /goma_server_patches.patch
RUN apt-get update && apt-get install -y git
RUN git clone --branch $GOMA_SERVER_VERSION https://chromium.googlesource.com/infra/goma/server
WORKDIR server

ARG APPLY_GOMA_SERVER_PATCHES
RUN sh -c "if $APPLY_GOMA_SERVER_PATCHES; then \
	git config user.email root@root \
	&& git config user.name root \
	&& git am /goma_server_patches.patch; \
	fi"
WORKDIR cmd/remoteexec_proxy
RUN go build

ENTRYPOINT [ "./remoteexec_proxy" ]

FROM build_env as bazel

ARG BAZEL_VERSION

RUN apt-get update && apt-get install -y wget unzip
RUN wget -O bazel-installer.sh https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh
RUN chmod +x bazel-installer.sh
RUN ./bazel-installer.sh

# Building of buildfarm images (worker and server)

FROM build_env as buildfarm

RUN apt-get update && apt-get install -y wget git unzip

## for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

## preesed tzdata, update package index, upgrade packages and install needed software
RUN echo "tzdata tzdata/Areas select Europe" > /tmp/preseed.txt; \
    echo "tzdata tzdata/Zones/Europe select Berlin" >> /tmp/preseed.txt; \
    debconf-set-selections /tmp/preseed.txt && \
    apt-get update && \
    apt-get install -y tzdata

RUN apt-get install -y default-jdk

ARG BAZEL_VERSION
RUN wget -O bazel-installer.sh https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh
RUN chmod +x bazel-installer.sh
RUN ./bazel-installer.sh

ARG BUILDFARM_VERSION
RUN git clone --depth=1 --branch $BUILDFARM_VERSION https://github.com/bazelbuild/bazel-buildfarm.git /bazel-buildfarm

WORKDIR /bazel-buildfarm
RUN bazel build //src/main/java/build/buildfarm/...

ARG BUILDFARM_DAEMON
ENV BUILDFARM_DAEMON_ENV=$BUILDFARM_DAEMON
ARG BUILDFARM_CONFIG
ENV BUILDFARM_CONFIG_ENV=$BUILDFARM_CONFIG
ENTRYPOINT bazel-bin/src/main/java/build/buildfarm/$BUILDFARM_DAEMON_ENV $BUILDFARM_CONFIG_ENV

# Building of buildbox images, using the base build environment

FROM build_env as buildbox

WORKDIR /tmp

ARG BUILDBOX_COMMON_VERSION
ARG BUILDBOX_WORKER_VERSION
ARG BUILDBOX_HOST_TOOLS_SHA

## for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

## preseed tzdata, update package index, upgrade packages and install needed software
RUN echo "tzdata tzdata/Areas select Europe" > /tmp/preseed.txt; \
    echo "tzdata tzdata/Zones/Europe select Berlin" >> /tmp/preseed.txt; \
    debconf-set-selections /tmp/preseed.txt && \
    apt-get update && \
    apt-get install -y tzdata

RUN \
	apt-get update \
	&& \
	apt-get install -y \
		build-essential git cmake pkg-config \
		libssl-dev libfuse3-dev uuid-dev \
		libprotobuf-dev protobuf-compiler \
		libgrpc-dev libgrpc++-dev protobuf-compiler-grpc \
		libgtest-dev libgmock-dev \
		python3 python3-pip \
		bubblewrap \
	&& \
	apt-get clean

RUN \
	git clone --depth=1 --branch $BUILDBOX_COMMON_VERSION \
		https://gitlab.com/BuildGrid/buildbox/buildbox-common.git \
		/tmp/buildbox-common \
	&& \
	cmake -B /tmp/buildbox-common/build /tmp/buildbox-common \
		-DBUILD_TESTING=OFF \
	&& \
	make -C /tmp/buildbox-common/build install \
	&& \
	rm -rf /tmp/buildbox-common

RUN \
	git clone https://gitlab.com/BuildGrid/buildbox/buildbox-run-hosttools.git \
		/tmp/buildbox-run-hosttools \
	&& \
	git --git-dir /tmp/buildbox-run-hosttools/.git checkout $BUILDBOX_HOST_TOOLS_SHA \
	&& \
	cmake -B /tmp/buildbox-run-hosttools/build /tmp/buildbox-run-hosttools \
		-DBUILD_TESTING=OFF \
	&& \
	make -C /tmp/buildbox-run-hosttools/build install \
	&& \
	rm -rf /tmp/buildbox-run-hosttools

RUN \
	git clone --depth=1 --branch $BUILDBOX_WORKER_VERSION \
		https://gitlab.com/BuildGrid/buildbox/buildbox-worker.git \
		/tmp/buildbox-worker \
	&& \
	cmake -B /tmp/buildbox-worker/build /tmp/buildbox-worker \
		-DBUILD_TESTING=OFF \
	&& \
	make -C /tmp/buildbox-worker/build install \
	&& \
	rm -rf /tmp/buildbox-worker

ENTRYPOINT ["buildbox-worker"]

## Building recc

FROM buildbox as recc

ARG RECC_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    libssl-dev \
    make \
    pkg-config \
    && apt-get clean

RUN git clone --depth=1 --branch $RECC_VERSION https://gitlab.com/BuildGrid/recc.git /recc

WORKDIR /recc

RUN mkdir build && cd build && \
        cmake -DBUILD_TESTING=OFF "${EXTRA_CMAKE_FLAGS}" .. && make

ENTRYPOINT []


# Pants client

FROM build_env as pants_client

# Ensure Python 3.6+ and other Pants dependencies are installed.
#
# Note: Pants is installed in the source repository by a wrapper script and not on
# any system path. Thus, there is no need to install Pants in this image.
ARG PANTS_COMMIT
RUN apt-get update && apt-get install -y curl git python3 python3-dev python3-distutils
RUN git clone --branch=main https://github.com/pantsbuild/example-python.git
WORKDIR /example-python
RUN git checkout $PANTS_COMMIT
