# speedtcli - LibreSpeed CLI
# Makefile for build, run, install, and package

PROGNAME     := speedtcli
DEFS_PATH    := github.com/librespeed/speedtest-cli
OUT_DIR      := out
INSTALL_PREFIX ?= /usr/local

# Version from git tag, or override with PROGVER= make build
PROGVER ?= $(shell git describe --tags 2>/dev/null || echo "dev")
BUILD_DATE   := $(shell date -u "+%Y-%m-%dT%H:%M:%SZ")
GOOS         := $(shell go env GOOS)
GOARCH       := $(shell go env GOARCH)

BINARY       := $(PROGNAME)-$(GOOS)-$(GOARCH)
ifeq ($(GOOS),windows)
  BINARY     := $(BINARY).exe
endif
ifdef GOARM
  BINARY     := $(BINARY)v$(GOARM)
endif
ifdef GOMIPS
  BINARY     := $(BINARY)-$(GOMIPS)
endif
ifdef GOMIPS64
  BINARY     := $(BINARY)-$(GOMIPS64)
endif

LDFLAGS      := -w -s \
  -X "$(DEFS_PATH)/defs.ProgName=$(PROGNAME)" \
  -X "$(DEFS_PATH)/defs.ProgVersion=$(PROGVER)" \
  -X "$(DEFS_PATH)/defs.BuildDate=$(BUILD_DATE)"

.PHONY: all build run install package clean help

all: build

## build: compile the binary to out/
build:
	@mkdir -p $(OUT_DIR)
	@echo "Building $(PROGNAME) $(PROGVER)..."
	CGO_ENABLED=0 go build -o $(OUT_DIR)/$(BINARY) -ldflags "$(LDFLAGS)" -trimpath main.go
	@if command -v upx >/dev/null 2>&1 && [ "$(GOARCH)" != "mips64" ] && [ "$(GOARCH)" != "mips64le" ]; then \
		upx -qqq -9 $(OUT_DIR)/$(BINARY); \
	fi
	@echo "Built: $(OUT_DIR)/$(BINARY)"

## run: build and run the CLI (pass args via ARGS, e.g. make run ARGS="--simple")
run: build
	@$(OUT_DIR)/$(BINARY) $(ARGS)

## install: install binary to $(INSTALL_PREFIX)/bin
install: build
	@mkdir -p $(INSTALL_PREFIX)/bin
	@cp $(OUT_DIR)/$(BINARY) $(INSTALL_PREFIX)/bin/$(PROGNAME)
	@echo "Installed: $(INSTALL_PREFIX)/bin/$(PROGNAME)"

## package: create distribution archives (tar.gz for Unix, zip for Windows)
package: build
	@mkdir -p dist
	@cp LICENSE $(OUT_DIR)/ 2>/dev/null || true
	@case $(GOOS) in \
		windows) \
			cd $(OUT_DIR) && zip -q ../dist/$(PROGNAME)-$(PROGVER)-$(GOOS)-$(GOARCH).zip $(BINARY) LICENSE 2>/dev/null || zip -q ../dist/$(PROGNAME)-$(PROGVER)-$(GOOS)-$(GOARCH).zip $(BINARY); \
			echo "Created dist/$(PROGNAME)-$(PROGVER)-$(GOOS)-$(GOARCH).zip"; \
			;; \
		*) \
			cd $(OUT_DIR) && tar czf ../dist/$(PROGNAME)-$(PROGVER)-$(GOOS)-$(GOARCH).tar.gz $(BINARY) LICENSE 2>/dev/null || tar czf ../dist/$(PROGNAME)-$(PROGVER)-$(GOOS)-$(GOARCH).tar.gz $(BINARY); \
			echo "Created dist/$(PROGNAME)-$(PROGVER)-$(GOOS)-$(GOARCH).tar.gz"; \
			;; \
	esac

## clean: remove build artifacts
clean:
	@rm -rf $(OUT_DIR) dist
	@echo "Cleaned $(OUT_DIR) and dist/"

## help: show this help
help:
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'
