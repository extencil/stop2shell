.PHONY: check test demo

check:
	bash -n stop2shell.sh
	@command -v dash >/dev/null 2>&1 && dash -n stop2shell.sh || true

test: check
	bash tests/smoke.sh

demo:
	@command -v vhs >/dev/null 2>&1 || { echo "vhs not found: https://github.com/charmbracelet/vhs"; exit 1; }
	vhs docs/demo.tape
