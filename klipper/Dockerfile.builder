FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
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

RUN git clone --depth 1 \
    https://github.com/Klipper3d/klipper.git

WORKDIR /opt/klipper

CMD ["make"]
