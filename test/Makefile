ifndef DOCKER_TAG
$(error DOCKER_TAG variable should contain the Docker tag being tested)
endif

SHELL = /bin/bash

makefile_path := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
TMP := $(shell mktemp -d)

# Generate a random token per invocation that can be used to disable/enable
# GitHub command processing.
stop_token := $(shell cat /dev/urandom | head -c 64 | sha256sum | head -c 64)

.PHONY: test
test: test-broken-links test-good

test-broken-links: broken-links.md
	@echo "::group::$@"
	@echo "::stop-commands::$(stop_token)"
	docker run --rm -v $(makefile_path):/data \
			-e INPUT_LINT=true \
			-e INPUT_PDF=false \
			-e INPUT_DOCX=false \
			$(DOCKER_TAG) \
			/data/broken-links.md &> $(TMP)/broken-links-actual.out
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
	docker run --rm -v $(makefile_path):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=true \
		-e INPUT_DOCX=false \
		-e INPUT_DRAFT=true \
		$(DOCKER_TAG) \
		/data/good.md
	@echo "::$(stop_token)::"
	@echo "::endgroup::"

good.docx: good.md
	@echo "::group::$@"
	@echo "::stop-commands::$(stop_token)"
	docker run --rm -v $(makefile_path):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=false \
		-e INPUT_DOCX=true \
		$(DOCKER_TAG) \
		/data/good.md
	@echo "::$(stop_token)::"
	@echo "::endgroup::"

good-redline.pdf: good.md good-diff.md
	@echo "::group::$@"
	@echo "::stop-commands::$(stop_token)"
	docker run --rm -v $(makefile_path):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=true \
		-e INPUT_DOCX=false \
		-e INPUT_DRAFT=true \
		-e INPUT_DIFF_FILE=/data/good-diff.md \
		$(DOCKER_TAG) \
		/data/good.md
	@echo "::$(stop_token)::"
	@echo "::endgroup::"

.PHONY: clean
clean:
	rm -rf *.pdf
	rm -rf *.docx
	rm -rf *.tex
