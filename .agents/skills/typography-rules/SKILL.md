# Typography rule changes

Use this playbook whenever a change affects `LintText`, sentence typography, quote conversion, spacing, dash/hyphen rules, emoji removal, phone/email normalization or fragment protection.

## Rule contract

Every rule change must define three examples before implementation:

- positive case: text that must change
- protected/negative case: similar text that must not change
- composition case: text where this rule runs next to another cleanup rule

Keep expected strings exact, including ordinary spaces, NBSP (U+00A0), non-breaking hyphen (U+2011), em dash and quote characters.

## Protection order

Before changing rule order, inspect the current pipeline in `LintText()` and `ProtectFragments()`.

URLs, email addresses, inline/fenced code and file paths are user data with special preservation requirements. Do not expand a regex across protected tokens or restore fragments before all intended cleanup passes have completed.

## Regex review checklist

- Is the expression anchored narrowly enough?
- Can it cross line boundaries unintentionally?
- Does it affect Latin and Cyrillic text differently?
- Does it alter identifiers, versions, URLs, paths, code or email addresses?
- Does it introduce NBSP or non-breaking hyphen only where intended?
- Does repeated execution produce the same result (idempotence) for the tested case?
- Does the replacement preserve punctuation adjacent to the match?

## Validation

Run:

```powershell
pwsh -File tests/repo-contract.ps1
```

GitHub Actions must also pass AutoHotkey v2 `/Validate`.

Until pure typography functions are extracted into a side-effect-free test module, record exact input/output vectors in the related GitHub issue or PR and perform representative transforms on Windows before merging.

If a rule cannot be expressed without a broad heuristic, document the accepted false-positive/false-negative trade-off instead of pretending regex has suddenly developed linguistic judgment.