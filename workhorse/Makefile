PREFIX=/usr/local
PKG := gitlab.com/gitlab-org/gitlab/workhorse
BUILD_DIR ?= $(CURDIR)
TARGET_DIR ?= $(BUILD_DIR)/_build
TARGET_SETUP := $(TARGET_DIR)/.ok
BIN_BUILD_DIR := $(TARGET_DIR)/bin
COVERAGE_DIR := $(TARGET_DIR)/cover
VERSION_STRING := $(shell git describe)
ifeq ($(strip $(VERSION_STRING)),)
VERSION_STRING := v$(shell cat VERSION)
endif
BUILD_TIME := $(shell date -u +%Y%m%d.%H%M%S)
GOBUILD := go build -ldflags "-X main.Version=$(VERSION_STRING) -X main.BuildTime=$(BUILD_TIME)"
EXE_ALL := gitlab-resize-image gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse
INSTALL := install
BUILD_TAGS := tracer_static tracer_static_jaeger continuous_profiler_stackdriver

MINIMUM_SUPPORTED_GO_VERSION := 1.11

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

$(TARGET_SETUP):
	$(call message,"Setting up target directory")
	rm -rf "$(TARGET_DIR)"
	mkdir -p "$(TARGET_DIR)"
	touch "$(TARGET_SETUP)"

.PHONY: gitlab-resize-image
gitlab-resize-image: $(TARGET_SETUP)
	$(call message,Building $@)
	$(GOBUILD) -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)/cmd/$@

.PHONY: gitlab-zip-cat
gitlab-zip-cat: $(TARGET_SETUP)
	$(call message,Building $@)
	$(GOBUILD) -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)/cmd/$@

.PHONY: gitlab-zip-metadata
gitlab-zip-metadata: $(TARGET_SETUP)
	$(call message,Building $@)
	$(GOBUILD) -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)/cmd/$@

.PHONY: gitlab-workhorse
gitlab-workhorse: $(TARGET_SETUP)
	$(call message,Building $@)
	$(GOBUILD) -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)

.PHONY:	install
install:	$(EXE_ALL)
	$(call message,$@)
	mkdir -p $(DESTDIR)$(PREFIX)/bin/
	cd $(BUILD_DIR) && $(INSTALL) $(EXE_ALL) $(DESTDIR)$(PREFIX)/bin/

.PHONY:	test
test: $(TARGET_SETUP) prepare-tests
	$(call message,$@)
	@go test -tags "$(BUILD_TAGS)" ./...
	@echo SUCCESS

.PHONY:	coverage
coverage:	$(TARGET_SETUP) prepare-tests
	$(call message,$@)
	@go test -tags "$(BUILD_TAGS)" -cover -coverprofile=test.coverage ./...
	go tool cover -html=test.coverage -o coverage.html
	rm -f test.coverage

.PHONY:	clean
clean:	clean-workhorse clean-build
	$(call message,$@)
	rm -rf testdata/data testdata/scratch

.PHONY:	clean-workhorse
clean-workhorse:
	$(call message,$@)
	rm -f $(EXE_ALL)

.PHONY: check-version
check-version:
	@test -n "$(VERSION)" || (echo "VERSION not set." ; exit 1)

.PHONY:	tag
tag: check-version
	$(call message,$@)
	sh _support/tag.sh "$(VERSION)"

.PHONY:	signed_tag
signed_tag: check-version
	$(call message,$@)
	TAG_OPTS=-s sh _support/tag.sh "$(VERSION)"

.PHONY:	clean-build
clean-build:
	$(call message,$@)
	rm -rf $(TARGET_DIR)

.PHONY:	prepare-tests
prepare-tests:	testdata/data/group/test.git $(EXE_ALL)
prepare-tests:	testdata/scratch

testdata/data/group/test.git:
	$(call message,$@)
	git clone --quiet --bare https://gitlab.com/gitlab-org/gitlab-test.git $@

testdata/scratch:
	mkdir -p testdata/scratch

.PHONY: verify
verify: lint vet detect-context detect-assert check-formatting staticcheck deps-check

.PHONY: lint
lint: $(TARGET_SETUP)
	$(call message,Verify: $@)
	go install golang.org/x/lint/golint
	@_support/lint.sh ./...

.PHONY: vet
vet: $(TARGET_SETUP) 
	$(call message,Verify: $@)
	@go vet ./...

.PHONY: detect-context
detect-context: $(TARGET_SETUP)
	$(call message,Verify: $@)
	_support/detect-context.sh

.PHONY: detect-assert
detect-assert:
	$(call message,Verify: $@)
	_support/detect-assert.sh

.PHONY: check-formatting
check-formatting: $(TARGET_SETUP) install-goimports
	$(call message,Verify: $@)
	@_support/fmt.sh check

# Megacheck will tailor some responses given a minimum Go version, so pass that through the CLI
# Additionally, megacheck will not return failure exit codes unless explicitly told to via the
# `-simple.exit-non-zero` `-unused.exit-non-zero` and `-staticcheck.exit-non-zero` flags
.PHONY: staticcheck
staticcheck: $(TARGET_SETUP)
	$(call message,Verify: $@)
	go install honnef.co/go/tools/cmd/staticcheck
	@ $(GOBIN)/staticcheck -go $(MINIMUM_SUPPORTED_GO_VERSION) ./...

# In addition to fixing imports, goimports also formats your code in the same style as gofmt
# so it can be used as a replacement.
.PHONY: fmt
fmt: $(TARGET_SETUP) install-goimports
	$(call message,$@)
	@_support/fmt.sh

.PHONY:	goimports
install-goimports:	$(TARGET_SETUP)
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
