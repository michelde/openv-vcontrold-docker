# Optimized Dockerfile with multi-stage build
FROM debian:stable-slim AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    subversion \
    automake \
    autoconf \
    libxml2-dev \
    git \
    cmake \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Build vcontrold
WORKDIR /openv
RUN git clone https://github.com/openv/vcontrold.git vcontrold-code && \
    cmake ./vcontrold-code -DVSIM=ON -DMANPAGES=OFF && \
    make && \
    make install

# Runtime stage
FROM debian:stable-slim

LABEL maintainer="michelde" \
      description="Viessmann Optolink Control based on OpenV library with MQTT support" \
      version="1.0"

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libxml2 \
    mosquitto-clients \
    jq \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Copy built binaries from builder stage
# vcontrold is installed to /usr/sbin, vclient and vsim to /usr/bin
COPY --from=builder /usr/sbin/vcontrold /usr/sbin/vcontrold
COPY --from=builder /usr/bin/vclient /usr/bin/vclient

# Copy configuration files
COPY config /etc/vcontrold/
COPY startup.sh /startup.sh

# Make startup script executable
RUN chmod +x /startup.sh

# Expose vcontrold port
EXPOSE 3002/tcp

# Health check to verify vcontrold is running
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD pidof vcontrold || exit 1

ENTRYPOINT ["/startup.sh"]
