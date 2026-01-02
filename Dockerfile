FROM ubuntu:22.04

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libboost-system1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-thread1.74.0 \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy binaries from build
COPY build/bin/* /usr/local/bin/

# Create data directory
RUN mkdir -p /bitminti-data

# Expose P2P and RPC ports
EXPOSE 13337 8332

# Use volume for persistent data
VOLUME ["/bitminti-data"]

# Default command
CMD ["bitmintid", \
     "-datadir=/bitminti-data", \
     "-server", \
     "-rpcuser=admin", \
     "-rpcpassword=admin", \
     "-rpcbind=0.0.0.0", \
     "-rpcallowip=0.0.0.0/0", \
     "-fallbackfee=0.00001", \
     "-printtoconsole"]

