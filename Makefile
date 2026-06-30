SHELL := /bin/bash -o pipefail

IDNA_DIR          := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IDNA_DATA         ?= $(HOME)/.roxabi/idna
SYSTEMD_USER_DIR  ?= $(HOME)/.config/systemd/user
IDNA_UNIT         := idna

ifndef SVC_CMD
ifeq (idna,$(firstword $(MAKECMDGOALS)))
  SVC_CMD := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifneq (,$(SVC_CMD))
    $(eval $(SVC_CMD):;@:)
  endif
endif
endif

.PHONY: idna ls clean install-service help

.DEFAULT_GOAL := help

help:
	@echo "Usage: make idna <action>  |  make <target>"
	@echo ""
	@echo "Service actions:"
	@echo "  make idna start|stop|reload|status|logs|errlogs"
	@echo ""
	@echo "Project targets:"
	@echo "  install-service  install idna systemd user unit"
	@echo "  ls               list sessions in $(IDNA_DATA)"
	@echo "  clean            remove all session dirs from $(IDNA_DATA)"

idna:
	@case "$(SVC_CMD)" in \
		start|"")       systemctl --user start $(IDNA_UNIT) ;; \
		stop)           systemctl --user stop $(IDNA_UNIT) ;; \
		reload|restart) systemctl --user restart $(IDNA_UNIT) ;; \
		status)         systemctl --user status $(IDNA_UNIT) || true ;; \
		logs)           journalctl --user -u $(IDNA_UNIT) -f ;; \
		errlogs|errors) journalctl --user -u $(IDNA_UNIT) -f -p err ;; \
		*) echo "Unknown action: $(SVC_CMD). Use: start|stop|reload|status|logs|errlogs"; exit 1 ;; \
	esac

install-service:
	@mkdir -p "$(SYSTEMD_USER_DIR)" "$(HOME)/.local/state/idna/logs"
	@install -m 644 "$(IDNA_DIR)deploy/systemd/idna.service" "$(SYSTEMD_USER_DIR)/$(IDNA_UNIT).service"
	@systemctl --user daemon-reload
	@echo "Installed $(SYSTEMD_USER_DIR)/$(IDNA_UNIT).service"
	@echo "Start with: systemctl --user start $(IDNA_UNIT)"

ls:
	@ls "$(IDNA_DATA)"

clean:
	@echo "Removing session dirs from $(IDNA_DATA)..."
	@find "$(IDNA_DATA)" -mindepth 1 -maxdepth 1 -type d \
		-exec rm -rf {} +
	@echo "Done."