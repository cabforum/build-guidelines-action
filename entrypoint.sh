#!/bin/bash

set -euo pipefail

INPUT_DRAFT="${INPUT_DRAFT:-false}"
INPUT_PDF="${INPUT_PDF:-true}"
INPUT_DOCX="${INPUT_DOCX:-true}"
INPUT_LINT="${INPUT_LINT:-false}"
TEXINPUTS="${TEXINPUTS:-}"

if [ "$#" -ne 1 ]; then
  echo "No markdown file specified"
  echo "Usage: $0 <markdown-file.md>"
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

PANDOC_ARGS=( -f markdown --table-of-contents -s )

if [ "$INPUT_DRAFT" = "true" ]; then
  echo "::debug::Adding draft watermark"
  PANDOC_ARGS+=( -M draft )
fi

# Build PDF
if [ "$INPUT_PDF" = "true" ]; then
  echo "::group::Building PDF"
  PANDOC_PDF_ARGS=( "${PANDOC_ARGS[@]}" )
  PANDOC_PDF_ARGS+=( -t latex --pdf-engine=xelatex )
  PANDOC_PDF_ARGS+=( --template=/cabforum/templates/guideline.latex )
  PANDOC_PDF_ARGS+=( -o "${BASE_FILE}.pdf" "${1}" )

  echo "::debug::${PANDOC_PDF_ARGS[@]}"
  TEXINPUTS="$TEXINPUTS":/cabforum/ pandoc "${PANDOC_PDF_ARGS[@]}"
  echo "::endgroup::"
fi

if [ "$INPUT_DOCX" = "true" ]; then
  echo "::group::Building DOCX"
  PANDOC_DOCX_ARGS=( "${PANDOC_ARGS[@]}" )
  PANDOC_DOCX_ARGS+=( -t docx )
  PANDOC_DOCX_ARGS+=( --reference-doc=/cabforum/templates/guideline.docx )
  PANDOC_DOCX_ARGS+=( -o "${BASE_FILE}.docx" "${1}" )

  echo "::debug::${PANDOC_DOCX_ARGS[@]}"
  pandoc "${PANDOC_DOCX_ARGS[@]}"
  echo "::endgroup::"
fi

if [ "$INPUT_LINT" = "true" ]; then
  echo "::group::Checking links"
  PANDOC_LINT_ARGS=( "${PANDOC_ARGS[@]}" )
  PANDOC_LINT_ARGS+=( -t gfm )
  PANDOC_LINT_ARGS+=( --lua-filter=/cabforum/filters/broken-links.lua )
  PANDOC_LINT_ARGS+=( -o /dev/null "${1}" )

  echo "::debug::${PANDOC_LINT_ARGS[@]}"
  pandoc "${PANDOC_LINT_ARGS[@]}"
  echo "::endgroup::"
fi
