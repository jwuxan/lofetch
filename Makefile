PREFIX ?= /usr/local

.PHONY: install uninstall test lint

install:
	install -m 755 lofetch $(PREFIX)/bin/lofetch

uninstall:
	rm -f $(PREFIX)/bin/lofetch

test:
	bash test_lofetch.sh

lint:
	shellcheck lofetch
