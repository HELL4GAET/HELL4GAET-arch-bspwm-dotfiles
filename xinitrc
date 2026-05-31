#!/bin/sh

export XDG_CURRENT_DESKTOP=bspwm
: "${XDG_SESSION_TYPE:=x11}"
export XDG_SESSION_TYPE

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
fi

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
fi

exec bspwm
