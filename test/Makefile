ifndef DOCKER_TAG
$(error DOCKER_TAG variable should contain the Docker tag being tested)
endif

SHELL = /bin/bash

TMP := $(shell mktemp -d)
GITHUB_OUTPUT ?= /dev/null
GITHUB_SHA ?= $(shell git rev-parse HEAD)
REPOSITORY = $(shell git rev-parse --show-toplevel)

# Generate a random token per invocation that can be used to disable/enable
# GitHub command processing.
stop_token := $(shell cat /dev/urandom | head -c 64 | sha256sum | head -c 64)

.PHONY: test
test: test-broken-links test-good

test-broken-links: broken-links.md
	@echo "::group::$@"
	@echo "::stop-commands::$(stop_token)"
	docker run --rm -v $(REPOSITORY):/data \
			-e INPUT_LINT=true \
			-e INPUT_PDF=false \
			-e INPUT_DOCX=false \
			-e INPUT_MARKDOWN_FILE=/data/test/broken-links.md \
			-v $(GITHUB_OUTPUT):$(GITHUB_OUTPUT) -e GITHUB_OUTPUT=${GITHUB_OUTPUT} \
			$(DOCKER_TAG) \
			2>&1 | tee $(TMP)/broken-links-actual.out
	diff -aurN expected/broken-links.out $(TMP)/broken-links-actual.out
	@echo "::$(stop_token)::"
	@echo "::endgroup::"

.PHONY: test-good
test-good: good.pdf good.docx good-redline.pdf

# TODO(rsleevi): This isn't quite correct, because it presumes a particular
# output path, which is not guaranteed by the Dockerfile, but instead
# communicated as part of the action outputs.
good.pdf: good.md
	@echo "::group::$@"
	@echo "::stop-commands::$(stop_token)"
	ls -lah
	docker run --rm -v $(REPOSITORY):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=true \
		-e INPUT_DOCX=false \
		-e INPUT_DRAFT=true \
		-e INPUT_MARKDOWN_FILE=/data/test/good.md \
		-e GITHUB_OUTPUT=${GITHUB_OUTPUT} \
		-v $(GITHUB_OUTPUT):$(GITHUB_OUTPUT) \
		$(DOCKER_TAG)
	@echo "::$(stop_token)::"
	@echo "::endgroup::"

good.docx: good.md
	@echo "::group::$@"
	@echo "::stop-commands::$(stop_token)"
	docker run --rm -v $(REPOSITORY):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=false \
		-e INPUT_DOCX=true \
		-e INPUT_MARKDOWN_FILE=/data/test/good.md \
		-e GITHUB_OUTPUT=${GITHUB_OUTPUT} \
		-v $(GITHUB_OUTPUT):$(GITHUB_OUTPUT) \
		$(DOCKER_TAG)
	@echo "::$(stop_token)::"
	@echo "::endgroup::"

good-redline.pdf: good.md good-diff.md
	@echo "::group::$@"
	@echo "::stop-commands::$(stop_token)"
	docker run --rm -v $(REPOSITORY):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=true \
		-e INPUT_DOCX=false \
		-e INPUT_DRAFT=true \
		-e INPUT_DIFF_FILE=/data/test/good-diff.md \
		-e INPUT_MARKDOWN_FILE=/data/test/good.md \
		-e GITHUB_OUTPUT=${GITHUB_OUTPUT} \
		-v $(GITHUB_OUTPUT):$(GITHUB_OUTPUT) \
		$(DOCKER_TAG)
	@echo "::$(stop_token)::"
	@echo "::endgroup::"

.PHONY: clean
clean:
	rm -rf *.pdf
	rm -rf *.docx
	rm -rf *.tex
