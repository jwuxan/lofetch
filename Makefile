PREFIX ?= /usr/local

.PHONY: install uninstall test test-package test-ci test-all lint help

install:
	install -m 755 lofetch $(PREFIX)/bin/lofetch

uninstall:
	rm -f $(PREFIX)/bin/lofetch

test:
	bash test_lofetch.sh

test-package:
	bash test_package.sh

test-ci:
	bash test_ci.sh

test-all: test test-package test-ci

lint:
	shellcheck lofetch

help:
	@echo "Lofetch Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  install       Install lofetch to $(PREFIX)/bin"
	@echo "  uninstall     Remove lofetch from $(PREFIX)/bin"
	@echo "  test          Run main test suite"
	@echo "  test-package  Run package structure tests"
	@echo "  test-ci       Run CI workflow validation tests"
	@echo "  test-all      Run all tests"
	@echo "  lint          Run shellcheck linter"
	@echo "  help          Show this help message"
