#!/usr/bin/env bash
set -euo pipefail

killall -q polybar || true

tries=0
while pgrep -x polybar >/dev/null && [ "$tries" -lt 10 ]; do
  sleep 0.2
  tries=$((tries + 1))
done

profile="$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/monitor-profile" 2>/dev/null || printf 'laptop')"
case "$profile" in
  external)
    bar=top-external
    ;;
  *)
    bar=top
    ;;
esac

if command -v xrandr >/dev/null 2>&1; then
  xrandr --query | awk '$2 == "connected" && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {print $1}' | while read -r monitor; do
    setsid -f env MONITOR="$monitor" polybar --reload "$bar" >>"/tmp/polybar-$monitor.log" 2>&1
  done
else
  setsid -f polybar --reload "$bar" >>/tmp/polybar.log 2>&1
fi
