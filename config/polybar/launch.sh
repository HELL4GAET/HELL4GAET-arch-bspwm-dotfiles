#!/usr/bin/env bash
set -euo pipefail

killall -q polybar || true

while pgrep -x polybar >/dev/null; do
  sleep 0.2
done

if command -v xrandr >/dev/null 2>&1; then
  xrandr --query | awk '$2 == "connected" && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {print $1}' | while read -r monitor; do
    setsid -f env MONITOR="$monitor" polybar --reload top >>"/tmp/polybar-$monitor.log" 2>&1
  done
else
  setsid -f polybar --reload top >>/tmp/polybar.log 2>&1
fi

if command -v bspc >/dev/null 2>&1; then
  sleep 0.3
  bspc config top_padding 44
fi
