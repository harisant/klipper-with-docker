#!/bin/bash
set -e

mkdir -p /opt/printer_data/config
mkdir -p /opt/printer_data/gcodes
mkdir -p /opt/printer_data/logs
mkdir -p /opt/printer_data/run

CONFIG_FILE="/opt/printer_data/config/printer.cfg"
PRINTER_TYPE="${PRINTER_TYPE:-ender3_pro}"
PROFILE_TEMPLATE="/opt/printer_configs/${PRINTER_TYPE}.cfg"
FALLBACK_TEMPLATE="/opt/printer_data/config/printer.cfg.template"

# Copy/force overwrite macros.cfg ke printer_data agar selalu update
if [ -f "/opt/printer_configs/macros.cfg" ]; then
    echo "Updating/copying latest macros.cfg template..."
    cp -f /opt/printer_configs/macros.cfg /opt/printer_data/config/macros.cfg
fi

# Always select template source and render printer.cfg
SOURCE_TEMPLATE=""
if [ -f "$PROFILE_TEMPLATE" ]; then
    echo "Using printer profile template: $PROFILE_TEMPLATE"
    SOURCE_TEMPLATE="$PROFILE_TEMPLATE"
elif [ -f "$FALLBACK_TEMPLATE" ]; then
    echo "Using fallback template: $FALLBACK_TEMPLATE"
    SOURCE_TEMPLATE="$FALLBACK_TEMPLATE"
fi

if [ -n "$SOURCE_TEMPLATE" ]; then
    /opt/klipper-env/bin/python -c '
import os, string
src = "'"$SOURCE_TEMPLATE"'"
dest = "'"$CONFIG_FILE"'"
with open(src, "r") as f:
    template = string.Template(f.read())
rendered = template.safe_substitute(os.environ)
with open(dest, "w") as f:
    f.write(rendered)
'
fi

exec /opt/klipper-env/bin/python \
    /opt/klipper/klippy/klippy.py \
    /opt/printer_data/config/printer.cfg \
    -a /opt/printer_data/run/klippy.sock \
    -l /opt/printer_data/logs/klippy.log


