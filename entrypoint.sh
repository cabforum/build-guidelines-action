#!/bin/bash

set -euo pipefail

INPUT_DRAFT="${INPUT_DRAFT:-false}"
INPUT_PDF="${INPUT_PDF:-true}"
INPUT_DOCX="${INPUT_DOCX:-true}"
INPUT_LINT="${INPUT_LINT:-false}"
INPUT_DIFF_FILE="${INPUT_DIFF_FILE:-}"
TEXINPUTS="${TEXINPUTS:-}"

# Rather than relying on 'set -x', which will output the command to STDERR,
# use a function that logs to STDOUT. This ensures a deterministic sequence
# of output (e.g. during tests), by writing everything to a single output.
#
# While 'set -x / set +x' gives a good degree of flexibility, the downside to
# this is that by default, stderr is unbuffered and stdout is buffered, and
# that when run under Docker, there is additional non-determinism in how
# outputs are logged, as captured at https://github.com/moby/moby/issues/31706
#
# See https://github.com/cabforum/build-guidelines-action/issues/11 for more
# history.
LogAndRun() {
  echo "$@"
  "$@"
}

if [ "$#" -ne 1 ]; then
  echo "No markdown file specified"
  echo "Usage: $0 <markdown_file.md>"
  exit 1
fi
if [ ! -f "$1" ]; then
  echo "Invalid file specified: ${1} cannot be found."
  exit 1
fi
if [ "${1##*.}" != "md" ] ; then
  echo "Invalid file specified: ${1} is not a Markdown file."
  exit 1
fi
BASE_FILE="${1%.*}"

DIFF_FILE=
if [ -n "${INPUT_DIFF_FILE}" ]; then
  if [ -f "${INPUT_DIFF_FILE}" ] && [[ "${INPUT_DIFF_FILE}" =~ .*\.md ]]; then
    DIFF_FILE="${INPUT_DIFF_FILE}"
  else
    echo "Skipping redline; unable to find ${INPUT_DIFF_FILE} or the filename doesn't end in .md"
  fi
fi

PANDOC_ARGS=( -f markdown+gfm_auto_identifiers --table-of-contents -s --no-highlight )

if [ "$INPUT_DRAFT" = "true" ]; then
  echo "Draft detected. Adding draft watermark"
  PANDOC_ARGS+=( -M draft )
fi

# Build PDF
if [ "$INPUT_PDF" = "true" ]; then
  echo "::group::Building PDF"
  PANDOC_PDF_ARGS=( "${PANDOC_ARGS[@]}" )
  PANDOC_PDF_ARGS+=( -t latex --pdf-engine=xelatex )
  PANDOC_PDF_ARGS+=( --template=/cabforum/templates/guideline.latex )
  PANDOC_PDF_ARGS+=( -o "${BASE_FILE}.pdf" "${1}" )

  LogAndRun pandoc "${PANDOC_ARGS[@]}" -t latex --template=/cabforum/templates/guideline.latex -o "${BASE_FILE}.tex" "${1}"
  TEXINPUTS="${TEXINPUTS}:/cabforum/" LogAndRun pandoc "${PANDOC_PDF_ARGS[@]}"
  echo "::set-output name=pdf_file::${BASE_FILE}.pdf"
  echo "::endgroup::"

  if [ -n "${DIFF_FILE}" ]; then
    echo "::group::Generating diff"
    TMP_DIR=$(mktemp -d)
    OUT_DIFF_TEX=$(basename "${DIFF_FILE}" ".md")
    OUT_DIFF_TEX="${TMP_DIR}/${OUT_DIFF_TEX}"
    LogAndRun pandoc "${PANDOC_ARGS[@]}" -t latex --template=/cabforum/templates/guideline.latex -o "${OUT_DIFF_TEX}.tex" "${DIFF_FILE}"
    LogAndRun latexdiff --packages=hyperref "${OUT_DIFF_TEX}.tex" "${BASE_FILE}.tex" > "${OUT_DIFF_TEX}-redline.tex"
    # Three runs in total are required (and match what Pandoc does under the hood)
    TEXINPUTS="${TEXINPUTS}:/cabforum/" LogAndRun xelatex -interaction=nonstopmode --output-directory="${TMP_DIR}" "${OUT_DIFF_TEX}-redline.tex" || true
    TEXINPUTS="${TEXINPUTS}:/cabforum/" LogAndRun xelatex -interaction=nonstopmode --output-directory="${TMP_DIR}" "${OUT_DIFF_TEX}-redline.tex" || true
    TEXINPUTS="${TEXINPUTS}:/cabforum/" LogAndRun xelatex -interaction=nonstopmode --output-directory="${TMP_DIR}" "${OUT_DIFF_TEX}-redline.tex" || true
    if [ -f "${OUT_DIFF_TEX}-redline.pdf" ]; then
      cp "${OUT_DIFF_TEX}-redline.pdf" "${BASE_FILE}-redline.pdf"
      echo "::set-output name=pdf_redline_file::${BASE_FILE}-redline.pdf"
    fi
    echo "::endgroup::"
  fi

fi

if [ "$INPUT_DOCX" = "true" ]; then
  echo "::group::Building DOCX"
  PANDOC_DOCX_ARGS=( "${PANDOC_ARGS[@]}" )
  PANDOC_DOCX_ARGS+=( -t docx )
  PANDOC_DOCX_ARGS+=( --reference-doc=/cabforum/templates/guideline.docx )
  PANDOC_DOCX_ARGS+=( -o "${BASE_FILE}.docx" "${1}" )

  LogAndRun pandoc "${PANDOC_DOCX_ARGS[@]}"
  echo "::set-output name=docx_file::${BASE_FILE}.docx"
  echo "::endgroup::"
fi

if [ "$INPUT_LINT" = "true" ]; then
  echo "::group::Checking links"
  PANDOC_LINT_ARGS=( "${PANDOC_ARGS[@]}" )
  PANDOC_LINT_ARGS+=( -t gfm )
  PANDOC_LINT_ARGS+=( --lua-filter=/cabforum/filters/broken-links.lua )
  PANDOC_LINT_ARGS+=( -o /dev/null "${1}" )

  LogAndRun pandoc "${PANDOC_LINT_ARGS[@]}"
  echo "::endgroup::"
fi
