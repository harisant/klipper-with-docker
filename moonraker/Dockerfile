# ==========================================
# BUILDER
# ==========================================
FROM python:3.11-slim-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

ARG MOONRAKER_VERSION=v0.11.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gcc \
    g++ \
    make \
    python3-dev \
    libffi-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone --branch ${MOONRAKER_VERSION} --depth 1 \
    https://github.com/Arksine/moonraker.git

WORKDIR /opt/moonraker

RUN python3 -m venv /opt/moonraker-env

RUN /opt/moonraker-env/bin/pip install --upgrade pip setuptools wheel

RUN /opt/moonraker-env/bin/pip install \
    --no-cache-dir \
    -r scripts/moonraker-requirements.txt


# ==========================================
# RUNTIME
# ==========================================
FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    libffi8 \
    libssl3 \
    libcurl4 \
    libsodium23 \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/moonraker /opt/moonraker
COPY --from=builder /opt/moonraker-env /opt/moonraker-env

RUN mkdir -p \
    /opt/printer_data/config \
    /opt/printer_data/database \
    /opt/printer_data/gcodes \
    /opt/printer_data/logs \
    /opt/printer_data/run

WORKDIR /opt/moonraker

CMD ["/opt/moonraker-env/bin/python", \
     "/opt/moonraker/moonraker/moonraker.py", \
     "-c", "/opt/printer_data/config/moonraker.conf"]
