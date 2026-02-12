PREFIX ?= /usr/local

.PHONY: install uninstall test lint

install:
	install -m 755 zfetch $(PREFIX)/bin/zfetch

uninstall:
	rm -f $(PREFIX)/bin/zfetch

test:
	bash test_zfetch.sh

lint:
	shellcheck zfetch
