.PHONY: check lint doctor dry-run

check:
	./tests/smoke.sh

lint:
	shellcheck install.sh xinitrc config/bspwm/bspwmrc \
		config/bspwm/scripts/monitor-switch.sh config/polybar/launch.sh \
		local/bin/* tests/*.sh
	shfmt -d -i 2 -ci install.sh config/polybar/launch.sh \
		local/bin/powermenu local/bin/warm-screen tests/*.sh
	shfmt -d -i 4 -ci config/bspwm/scripts/monitor-switch.sh

doctor:
	./install.sh --doctor

dry-run:
	./install.sh --dry-run --all
