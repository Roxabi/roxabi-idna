IDNA_DIR  := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IDNA_DATA ?= $(HOME)/.roxabi/idna

.PHONY: run ls clean help

.DEFAULT_GOAL := help

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "  run     start picker server on :8082 (foreground, Ctrl+C)"
	@echo "  ls      list sessions in $(IDNA_DATA)"
	@echo "  clean   remove all session dirs from $(IDNA_DATA)"

run:
	cd "$(IDNA_DIR)" && exec uv run idna_server.py

ls:
	@ls "$(IDNA_DATA)"

clean:
	@echo "Removing session dirs from $(IDNA_DATA)..."
	@find "$(IDNA_DATA)" -mindepth 1 -maxdepth 1 -type d \
		-exec rm -rf {} +
	@echo "Done."