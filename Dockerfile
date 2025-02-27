# Build stage: Use Ubuntu 22.04 as the base to align GLIBC versions
FROM ubuntu:22.04 AS builder

# Install dependencies for building Rust apps
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# Copy Cargo files first (for caching)
COPY Cargo.toml Cargo.lock ./

# Create a dummy src directory to avoid build errors if src is missing
RUN mkdir -p src && echo 'fn main() {}' > src/main.rs

# Fetch dependencies
RUN cargo fetch

# Copy actual source code
COPY . .

# Build the Rust application (this will build against Ubuntu 22.04's GLIBC)
RUN cargo build --release

# Final stage: Use Ubuntu 22.04 for runtime
FROM ubuntu:22.04
WORKDIR /usr/local/bin

# Update and install libc6 (should be GLIBC 2.35 on Ubuntu 22.04)
RUN apt-get update && apt-get install -y libc6 && rm -rf /var/lib/apt/lists/*

# (Optional) Check GLIBC version to verify
RUN ldd --version

# Copy the Rust binary from the builder stage
COPY --from=builder /app/target/release/api_gateway .

# Set execution permissions
RUN chmod +x api_gateway

# (Optional) Check dynamic dependencies
RUN ldd api_gateway || echo "api_gateway is statically linked"

# Run the application
CMD ["./api_gateway"]
