FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

ARG KLIPPER_VERSION=v0.13.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    python3 \
    python3-dev \
    build-essential \
    libncurses-dev \
    libusb-1.0-0-dev \
    gcc-avr \
    avr-libc \
    avrdude \
    binutils-avr \
    libnewlib-arm-none-eabi \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone \
    --branch ${KLIPPER_VERSION} \
    --depth 1 \
    https://github.com/Klipper3d/klipper.git \
    /opt/klipper

WORKDIR /opt/klipper

CMD ["make"]
