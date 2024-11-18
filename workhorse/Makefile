PREFIX=/usr/local

FIPS_MODE ?= 0
PKG := gitlab.com/gitlab-org/gitlab/workhorse
BUILD_DIR ?= $(CURDIR)
TARGET_DIR ?= $(BUILD_DIR)/_build
VERSION_STRING := $(shell git describe)
ifeq ($(strip $(VERSION_STRING)),)
VERSION_STRING := v$(shell cat VERSION)
endif
DATE_FMT = +%Y%m%d.%H%M%S
ifdef SOURCE_DATE_EPOCH
	BUILD_TIME := $(shell date -u -d "@$(SOURCE_DATE_EPOCH)" "$(DATE_FMT)" 2>/dev/null || date -u -r "$(SOURCE_DATE_EPOCH)" "$(DATE_FMT)" 2>/dev/null || date -u "$(DATE_FMT)")
else
	BUILD_TIME := $(shell date -u "$(DATE_FMT)")
endif
GO_BUILD_GENERIC_LDFLAGS := -X main.Version=$(VERSION_STRING) -X main.BuildTime=$(BUILD_TIME)
GITALY  := tmp/tests/gitaly/_build/bin/gitaly
GITALY_PID_FILE := gitaly.pid
EXE_ALL := gitlab-resize-image gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse
INSTALL := install
BUILD_TAGS := tracer_static tracer_static_jaeger continuous_profiler_stackdriver

OS := $(shell uname | tr A-Z a-z)
ARCH ?= $(shell uname -m | sed -e 's/x86_64/amd64/' | sed -e 's/aarch64/arm64/')

GOLANGCI_LINT_VERSION := 1.60.3
GOLANGCI_LINT_ARCH ?= ${ARCH}
GOLANGCI_LINT_FILE := _support/bin/golangci-lint-${GOLANGCI_LINT_VERSION}

ifeq (${FIPS_MODE}, 1)
    # boringcrypto tag is added automatically by golang-fips compiler
    BUILD_TAGS += fips
    # If the golang-fips compiler is built with CGO_ENABLED=0, this needs to be
    # explicitly switched on.
    export CGO_ENABLED=1
    # Go 1.19+ now requires GOEXPERIMENT=boringcrypto for FIPS compilation.
    # See https://github.com/golang/go/issues/51940 for more details.
    ifeq ($(shell GOEXPERIMENT=boringcrypto go version > /dev/null 2>&1; echo $$?), 0)
      export GOEXPERIMENT=boringcrypto
    endif
endif

export GOBIN := $(TARGET_DIR)/bin
export PATH := $(GOBIN):$(PATH)
export GOPROXY ?= https://proxy.golang.org
export GO111MODULE=on

define message
	@echo "### $(1)"
endef

.NOTPARALLEL:

.PHONY:	all
all:	clean-build $(EXE_ALL)

.PHONY: gitlab-resize-image gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse
gitlab-resize-image gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse:
	$(call message,Building $@)
	go build -ldflags "$(GO_BUILD_GENERIC_LDFLAGS) -B gobuildid" -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)/cmd/$@

.PHONY:	install
install: $(EXE_ALL)
	$(call message,$@)
	mkdir -p $(DESTDIR)$(PREFIX)/bin/
	cd $(BUILD_DIR) && $(INSTALL) $(EXE_ALL) $(DESTDIR)$(PREFIX)/bin/

.PHONY:	test
test: prepare-tests
	$(call message,$@)
	@if [ -z "$${GITALY_ADDRESS+x}" ] ; then \
		echo "To run gitaly integration tests set GITALY_ADDRESS=tcp://127.0.0.1:8075" ; \
	else \
		$(MAKE) run-gitaly ; \
	fi
	go test ${TEST_OPTIONS} -tags "$(BUILD_TAGS)" ./...
	@status="$$?" ;\
	if [ -f "$(GITALY_PID_FILE)" ] ; then \
		echo "Clean up Gitaly server for workhorse integration test" ;\
		kill -9 $$(cat $(GITALY_PID_FILE)) ;\
		rm $(GITALY_PID_FILE) ;\
	else \
		echo "Gitaly integration test not running" ;\
	fi ;\
	exit "$$status"
	@echo SUCCESS

.PHONY: test-race
test-race: TEST_OPTIONS = -race
test-race: test

.PHONY: test-coverage
test-coverage: TEST_OPTIONS = -cover -coverprofile=cover.out
test-coverage: test
	$(call message, "Calculating the coverage")
	[ -f cover.out ] && go tool cover -html cover.out -o coverage.html
	[ -f cover.out ] && go tool cover -func cover.out

.PHONY:	clean
clean: clean-workhorse clean-build
	$(call message,$@)
	rm -rf testdata/data testdata/scratch cover.out coverage.html

.PHONY:	clean-workhorse
clean-workhorse:
	$(call message,$@)
	rm -f $(EXE_ALL)

.PHONY:	clean-build
clean-build:
	$(call message,$@)
	rm -rf $(TARGET_DIR)

.PHONY:	prepare-tests
prepare-tests: testdata/scratch $(EXE_ALL)

.PHONY: run-gitaly
run-gitaly: $(GITALY_PID_FILE)

$(GITALY_PID_FILE): gitaly.toml
	$(call message, "Starting gitaly")
	cd ..; GITALY_TESTING_NO_GIT_HOOKS=1 GITALY_PID_FILE=workhorse/$(GITALY_PID_FILE) scripts/gitaly-test-spawn workhorse/gitaly.toml

GITALY_CONFIGURATION_SOURCE_BASE = ../tmp/tests/gitaly/config.toml
ifeq ($(GITALY_TRANSACTIONS_ENABLED),true)
	GITALY_CONFIGURATION_SOURCE = ${GITALY_CONFIGURATION_SOURCE_BASE}.transactions
else
	GITALY_CONFIGURATION_SOURCE = ${GITALY_CONFIGURATION_SOURCE_BASE}
endif

# Mark the target phony so the configuration is always refreshed in case the `GITALY_TRANSACTIONS_ENABLED`
# environment variable has been changed.
.PHONY: gitaly.toml
gitaly.toml: ${GITALY_CONFIGURATION_SOURCE}
	sed -e 's/^socket_path.*$$/listen_addr = "0.0.0.0:8075"/;s/^\[auth\]$$//;s/^token.*$$//;s/^internal_socket_dir.*$$//' \
		$< > $@

../tmp/tests/gitaly/config.toml:
	$(call message, "Building a complete test environment")
	cd .. ; ./scripts/setup-test-env

testdata/scratch:
	mkdir -p testdata/scratch

.PHONY: verify
verify: lint vet detect-context detect-external-tests check-formatting staticcheck deps-check

.PHONY: lint
lint:
	$(call message,Verify: $@)
	@_support/lint.sh ./...

.PHONY: golangci
golangci: ${GOLANGCI_LINT_FILE}
	@${GOLANGCI_LINT_FILE} cache clean
	@${GOLANGCI_LINT_FILE} run --issues-exit-code 0 --print-issued-lines=false ${GOLANGCI_LINT_ARGS}

${GOLANGCI_LINT_FILE}:
	@mkdir -p $(shell dirname ${GOLANGCI_LINT_FILE})
	@curl -L https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-${OS}-${GOLANGCI_LINT_ARCH}.tar.gz | tar --strip-components 1 -zOxf - golangci-lint-${GOLANGCI_LINT_VERSION}-${OS}-${GOLANGCI_LINT_ARCH}/golangci-lint > ${GOLANGCI_LINT_FILE} && chmod +x ${GOLANGCI_LINT_FILE}

.PHONY: vet
vet:
	$(call message,Verify: $@)
	@go vet ./...

.PHONY: detect-context
detect-context:
	$(call message,Verify: $@)
	_support/detect-context.sh

.PHONY: detect-external-tests
detect-external-tests:
	$(call message,Verify: $@)
	_support/detect-external-tests.sh

.PHONY: check-formatting
check-formatting: install-goimports
	$(call message,Verify: $@)
	@_support/fmt.sh check

# Megacheck will tailor some responses given a minimum Go version, so pass that through the CLI
# Additionally, megacheck will not return failure exit codes unless explicitly told to via the
# `-simple.exit-non-zero` `-unused.exit-non-zero` and `-staticcheck.exit-non-zero` flags
.PHONY: staticcheck
staticcheck:
	$(call message,Verify: $@)
	go install honnef.co/go/tools/cmd/staticcheck@latest
	@ $(GOBIN)/staticcheck ./...

# In addition to fixing imports, goimports also formats your code in the same style as gofmt
# so it can be used as a replacement.
.PHONY: fmt
fmt: install-goimports
	$(call message,$@)
	@_support/fmt.sh

.PHONY:	goimports
install-goimports:
	$(call message,$@)
	go install golang.org/x/tools/cmd/goimports

.PHONY: deps-check
deps-check:
	go mod tidy
	@if git diff --quiet --exit-code -- go.mod go.sum; then \
		echo "go.mod and go.sum are ok"; \
	else \
		echo ""; \
		echo "go.mod and go.sum are modified, please commit them";\
		exit 1; \
	fi;
