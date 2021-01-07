ifndef DOCKER_TAG
$(error DOCKER_TAG variable should contain the Docker tag being tested)
endif

makefile_path := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: test
test: test-broken-links test-good

test-broken-links: broken-links.md
	docker run --rm -v $(makefile_path):/data \
			-e INPUT_LINT=true \
			-e INPUT_PDF=false \
			-e INPUT_DOCX=false \
			$(DOCKER_TAG) \
			/data/broken-links.md 2>&1 | diff -aurN expected/broken-links.out -

.PHONY: test-good
test-good: good.pdf good.docx good-redline.pdf

# TODO(rsleevi): This isn't quite correct, because it presumes a particular
# output path, which is not guaranteed by the Dockerfile, but instead
# communicated as part of the action outputs.
good.pdf: good.md
	docker run --rm -v $(makefile_path):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=true \
		-e INPUT_DOCX=false \
		-e INPUT_DRAFT=true \
		$(DOCKER_TAG) \
		/data/good.md

good.docx: good.md
	docker run --rm -v $(makefile_path):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=false \
		-e INPUT_DOCX=true \
		$(DOCKER_TAG) \
		/data/good.md

good-redline.pdf: good.md good-diff.md
	docker run --rm -v $(makefile_path):/data \
		-e INPUT_LINT=false \
		-e INPUT_PDF=true \
		-e INPUT_DOCX=false \
		-e INPUT_DRAFT=true \
		-e INPUT_DIFF_FILE=/data/good-diff.md \
		$(DOCKER_TAG) \
		/data/good.md

.PHONY: clean
clean:
	rm -rf *.pdf
	rm -rf *.docx
	rm -rf *.tex
