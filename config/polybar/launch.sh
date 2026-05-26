#!/usr/bin/env bash
set -euo pipefail

killall -q polybar || true

while pgrep -x polybar >/dev/null; do
  sleep 0.2
done

if command -v xrandr >/dev/null 2>&1; then
  xrandr --query | awk '/ connected/{print $1}' | while read -r monitor; do
    setsid -f env MONITOR="$monitor" polybar --reload top >>"/tmp/polybar-$monitor.log" 2>&1
  done
else
  setsid -f polybar --reload top >>/tmp/polybar.log 2>&1
fi
