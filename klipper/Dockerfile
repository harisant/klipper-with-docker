# ============================================================
# BUILDER
# ============================================================
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

ARG KLIPPER_VERSION=v0.13.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-venv \
    python3-dev \
    build-essential \
    libffi-dev \
    libssl-dev \
    libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone specific Klipper version
RUN git clone --branch ${KLIPPER_VERSION} \
    --depth 1 \
    https://github.com/Klipper3d/klipper.git \
    /opt/klipper

# Python environment
RUN python3 -m venv /opt/klipper-env

RUN /opt/klipper-env/bin/pip install \
    --no-cache-dir \
    -r /opt/klipper/scripts/klippy-requirements.txt


# ============================================================
# RUNTIME
# ============================================================
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libc6-dev \
    python3 \
    libffi8 \
    libssl3 \
    libusb-1.0-0 \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/klipper /opt/klipper
COPY --from=builder /opt/klipper-env /opt/klipper-env

RUN mkdir -p \
    /opt/printer_data/config \
    /opt/printer_data/gcodes \
    /opt/printer_data/logs \
    /opt/printer_data/run

RUN ln -s /opt/printer_data/gcodes /root/printer_data/gcodes

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
