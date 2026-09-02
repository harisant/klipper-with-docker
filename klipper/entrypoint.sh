#!/bin/bash
set -e

mkdir -p /opt/printer_data/config
mkdir -p /opt/printer_data/gcodes
mkdir -p /opt/printer_data/logs
mkdir -p /opt/printer_data/run

exec /opt/klipper-env/bin/python \
    /opt/klipper/klippy/klippy.py \
    /opt/printer_data/config/printer.cfg \
    -a /opt/printer_data/run/klippy.sock \
    -l /opt/printer_data/logs/klippy.log
