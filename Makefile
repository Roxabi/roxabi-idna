IDNA_DIR        := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IDNA_DATA       ?= $(HOME)/.roxabi/idna
SUPERVISOR_HUB  ?= $(HOME)/projects
HUB_SERVICES    := idna
-include $(SUPERVISOR_HUB)/hub.mk

.PHONY: idna ls clean help

.DEFAULT_GOAL := help

help:
	@echo "Usage: make idna <action>  |  make <target>"
	@echo ""
	@echo "Service actions (via hub or from this dir):"
	@echo "  make idna start|stop|reload|status|logs|errlogs"
	@echo ""
	@echo "Project targets:"
	@echo "  ls       list sessions in $(IDNA_DATA)"
	@echo "  clean    remove all session dirs from $(IDNA_DATA)"

# ── Supervisor service (hub-dispatched) ──────────────────────────────────────
# Registration lives in roxabi-plugins/plugins/idna; this Makefile is
# runtime-only. Dispatcher follows the canonical pattern (see forge, lyra).

idna:
	@case "$(SVC_CMD)" in \
		start|reload) \
			if [ ! -f "$(IDNA_DIR)idna_server.py" ]; then \
				echo "Error: idna not initialized at $(IDNA_DIR)"; \
				exit 1; \
			fi ;; \
	esac
	@$(HUB_SVC) idna $(SVC_CMD)

# ── Project targets ──────────────────────────────────────────────────────────

ls:
	@ls "$(IDNA_DATA)"

clean:
	@echo "Removing session dirs from $(IDNA_DATA)..."
	@find "$(IDNA_DATA)" -mindepth 1 -maxdepth 1 -type d \
		-exec rm -rf {} +
	@echo "Done."
