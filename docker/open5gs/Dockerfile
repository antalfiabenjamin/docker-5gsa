# Stage 1: Build 
FROM ubuntu:22.04 AS builder

ARG OPEN5GS_VERSION=v2.7.5
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3-setuptools python3-wheel \
    ninja-build build-essential flex bison git cmake \
    libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev \
    libmongoc-dev libbson-dev libyaml-dev \
    libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
    libtins-dev libtalloc-dev meson pkg-config \
    ca-certificates && \
    # Install libidn
    if apt-cache show libidn-dev > /dev/null 2>&1; then \
        apt-get install -y --no-install-recommends libidn-dev; \
    else \
        apt-get install -y --no-install-recommends libidn11-dev; \
    fi && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --depth 1 --branch ${OPEN5GS_VERSION} https://github.com/open5gs/open5gs.git

WORKDIR /opt/open5gs
RUN meson build \
        --prefix=/open5gs/install && \
    ninja -C build && \
    cd build && ninja install

# Stage 2: Runtime 
FROM ubuntu:22.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsctp1 libgnutls30 libgcrypt20 libssl3 \
    libmongoc-1.0-0 libbson-1.0-0 libyaml-0-2 \
    libnghttp2-14 libmicrohttpd12 libcurl3-gnutls \
    libtins4.0 libtalloc2 \
    iproute2 iptables iputils-ping net-tools \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    if apt-cache show libidn12 > /dev/null 2>&1; then \
        apt-get install -y --no-install-recommends libidn12; \
    else \
        apt-get install -y --no-install-recommends libidn11; \
    fi && \
    rm -rf /var/lib/apt/lists/*


COPY --from=builder /open5gs/install/ /open5gs/install/
ENV PATH="/open5gs/install/bin:${PATH}"

RUN mkdir -p /open5gs/install/var/log/open5gs

ENTRYPOINT ["/bin/bash", "-c"]
