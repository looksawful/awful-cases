# Published project page

`docs/index.html` is the checked-in source of truth for the GitHub Pages project/trainer preview.

## Provenance

The repository does not contain a separate website source tree, package manifest, build script, template, or generator for this page. Git history shows the file being added and later replaced/refined directly (`Add project page`, `Replace docs page with Win98 preview`, `Add English Awful Cases trainer preview`). No reproducible external generator or canonical source location is recorded in the repository.

Because the original authoring/export tool cannot be reconstructed from repository evidence, do not invent one. Operationally, treat the committed `docs/index.html` itself as the canonical source until a separate source project is explicitly introduced and documented here.

## Editing policy

- Direct edits are allowed only for an explicit website/trainer task.
- Do not reformat or minify the whole file as part of application work.
- Keep website changes separate from AutoHotkey behavior changes whenever practical.
- Review large diffs carefully because the file is self-contained and over 1 MB.
- Preserve `docs/.nojekyll` unless GitHub Pages deployment strategy intentionally changes.

## Rebuild / publish

There is currently no build step. Publishing is the repository state under `docs/` as consumed by GitHub Pages.

If a generator, design source, or separate web project is introduced later, this document must be updated with:

1. the canonical source location;
2. required tool/runtime versions;
3. the exact build/export command;
4. where generated output is copied;
5. whether direct edits to `docs/index.html` remain allowed.
