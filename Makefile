IDNA_DIR        := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IDNA_DATA       ?= $(HOME)/.roxabi/idna

.PHONY: ls clean help

.DEFAULT_GOAL := help

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Service:"
	@echo "  uv run idna_server.py        start the picker server (port 8082)"
	@echo ""
	@echo "Project targets:"
	@echo "  ls       list sessions in $(IDNA_DATA)"
	@echo "  clean    remove all session dirs from $(IDNA_DATA)"

# ── Project targets ──────────────────────────────────────────────────────────

ls:
	@ls "$(IDNA_DATA)"

clean:
	@echo "Removing session dirs from $(IDNA_DATA)..."
	@find "$(IDNA_DATA)" -mindepth 1 -maxdepth 1 -type d \
		-exec rm -rf {} +
	@echo "Done."
