########################################
# Stage 1: Build UERANSIM from source
########################################
FROM ubuntu:22.04 AS builder

ARG UERANSIM_VERSION=v3.2.7
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential g++ cmake git \
    libsctp-dev lksctp-tools \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --depth 1 --branch ${UERANSIM_VERSION} https://github.com/aligungr/UERANSIM.git

WORKDIR /opt/UERANSIM
RUN make

########################################
# Stage 2: Runtime image
########################################
FROM ubuntu:22.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsctp1 lksctp-tools \
    iproute2 iptables iputils-ping net-tools \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy built binaries
COPY --from=builder /opt/UERANSIM/build/ /ueransim/bin/

# Add binaries to PATH
ENV PATH="/ueransim/bin:${PATH}"

# Create config directory
RUN mkdir -p /ueransim/config

WORKDIR /ueransim
