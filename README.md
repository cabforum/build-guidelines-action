# CA/Browser Forum Guideline builder action

This action customizes the [Pandoc dockerfiles](https://github.com/pandoc/dockerfiles)
for use by [CA/Browser Forum](https://www.cabforum.org) Chartered Working
Groups to automatically produce Draft and Final Guidelines.

## Inputs

### `markdown_file`

**Required** The name of the Markdown file to convert. This should be relative
to [`GITHUB_WORKSPACE`](https://docs.github.com/en/free-pro-team@latest/actions/reference/environment-variables).

In general, running [`actions/checkout`](https://github.com/actions/checkout)
for the CWG repository is a necessary step before invoking this action, and
allows just passing the filename relative to the current repository.

### `diff_file`

Optional: The path, relative to
[`GITHUB_WORKSPACE`](https://docs.github.com/en/free-pro-team@latest/actions/reference/environment-variables),
that contains the previous "version" of `markdown_file`.

For example, on a `push` event, this would be the
[`before`](https://docs.github.com/en/free-pro-team@latest/developers/webhooks-and-events/webhook-events-and-payloads#push)
SHA-1's file (e.g. using [`actions/checkout`](https://github.com/actions/checkout)
with a `ref` of `${{ github.event.push.before }}` and a custom `path`).

This is fairly experimental and prone to break. Redlines are only generated
if `pdf` is `"true"`. Further, if this path does not exist, a redline is
simply not generated.

### `pdf`

Generate a PDF from `markdown_file`. Default: `"true"`.

The resulting PDF will be in the same directory of `GITHUB_WORKSPACE` as the
input file, but with a `pdf` extension.

### `docx`

Generate a DOCX. Default: `"true"`.

The resulting PDF will be in the same directory of `GITHUB_WORKSPACE` as the
input file, but with a `docx` extension.

### `lint`

Check that all self-referencing links resolve. Default: `"false"`.

This runs a simple [Pandoc Lua filter](https://pandoc.org/lua-filters.html) to
check and make sure that links to section headers resolve. Note that Pandoc
removes leading numbers for sections, so the following would be valid:

```
# 1.1 Good Example

This is a link to the [Good Example](#good-example)
```

But this would fail:
```
# 1.1 Broken Example

This is a link to the [broken example](#1.1-broken-example)
```

### `draft`

Add a "DRAFT" watermark to the resulting document. Default: `"false"`

This is currently only supported for PDF outputs.

## Outputs

### `pdf_file`

The path to the generated PDF file, if `pdf` was `"true"`, relative to
`GITHUB_WORKSPACE`.

### `docx_file`

The path to the generated DOCX file, if `docx` was `"true"`, relative to
`GITHUB_WORKSPACE`.

### `pdf_redline_file`

The path to the generated PDF redline, if `pdf` was `"true"` and `diff_file`
provided a path to a valid Markdown file.

### `file_version`

The version of the file, as extracted from the subtitle of the document.

### `file_commit`

The short commit hash of the file.

### `diff_version`

The version of the diff file, as extracted from the subtitle of the document.

### `diff_commit`

The short commit hash of the diff file.

### `changelog`

A list of commit messages from `diff_commit` to `file_commit`.

## Example usage

```
uses: cabforum/build-guidelines-action@v1
with:
  markdown_file: docs/BR.md
  draft: true
  lint: true
```
