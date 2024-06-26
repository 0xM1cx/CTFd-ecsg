# Use Python 3.11 slim image as the base for the build stage
FROM python:3.11-slim-bookworm as build

# Set the working directory
WORKDIR /opt/CTFd

# Install required packages including Go
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
        wget \
    && wget https://golang.org/dl/go1.20.3.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz \
    && rm go1.20.3.linux-amd64.tar.gz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python -m venv /opt/venv

# Set Go and Python paths
ENV PATH="/opt/venv/bin:/usr/local/go/bin:$PATH"

# Copy the application code
COPY . /opt/CTFd

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt";\
        fi; \
    done;

# Use Python 3.11 slim image as the base for the release stage
FROM python:3.11-slim-bookworm as release

# Set the working directory
WORKDIR /opt/CTFd

# Install required runtime packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libffi8 \
        libssl3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy the application code
COPY --chown=1001:1001 . /opt/CTFd

# Create a user for running the application
RUN useradd \
    --no-log-init \
    --shell /bin/bash \
    -u 1001 \
    ctfd \
    && mkdir -p /var/log/CTFd /var/uploads \
    && chown -R 1001:1001 /var/log/CTFd /var/uploads /opt/CTFd \
    && chmod +x /opt/CTFd/docker-entrypoint.sh

# Copy the Python environment from the build stage
COPY --chown=1001:1001 --from=build /opt/venv /opt/venv

# Set the Python path
ENV PATH="/opt/venv/bin:$PATH"

# Set the user to run the application
USER 1001

# Expose the application port
EXPOSE 8000

# Set the entry point for the container
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
