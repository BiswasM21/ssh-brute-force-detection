FROM kalilinux/kali-rolling:latest

LABEL maintainer="SSH BFD Project"
LABEL description="Kali Linux for SSH brute-force attack simulation"

# Install Metasploit and tools
RUN apt-get update && apt-get install -y \
    metasploit-framework \
    nmap \
    hydra \
    curl \
    wget \
    git \
    net-tools \
    dnsutils \
    iputils-ping \
    vim \
    nano \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install additional tools
RUN pip3 install --no-cache-dir paramiko

# Create working directory
WORKDIR /scripts

# Copy attack scripts
COPY attack-scripts/* /scripts/
COPY attack-scripts/* /usr/local/bin/

# Make scripts executable
RUN chmod +x /scripts/*.sh

# Expose any needed ports
EXPOSE 22

# Default command
CMD ["/bin/bash"]
