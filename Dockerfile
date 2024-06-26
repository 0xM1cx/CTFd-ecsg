# Stage 1: Build
FROM python:3.11-slim-bookworm as build

WORKDIR /opt/CTFd

# Install dependencies and Go
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://go.dev/dl/go1.20.6.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.20.6.linux-amd64.tar.gz \
    && rm go1.20.6.linux-amd64.tar.gz \
    && python -m venv /opt/venv

ENV PATH="/opt/venv/bin:/usr/local/go/bin:$PATH"

COPY . /opt/CTFd

RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt"; \
        fi; \
    done;

# Stage 2: Release
FROM python:3.11-slim-bookworm as release
WORKDIR /opt/CTFd

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libffi8 \
        libssl3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=1001:1001 . /opt/CTFd

RUN useradd \
    --no-log-init \
    --shell /bin/bash \
    -u 1001 \
    ctfd \
    && mkdir -p /var/log/CTFd /var/uploads \
    && chown -R 1001:1001 /var/log/CTFd /var/uploads /opt/CTFd \
    && chmod +x /opt/CTFd/docker-entrypoint.sh

COPY --chown=1001:1001 --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

USER 1001
EXPOSE 8000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
