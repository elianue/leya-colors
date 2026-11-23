# Feasibility and references

Research date: 2026-11-24. This is a technical development record, not a competition application.

## Tooling and structure

- Official installation: https://www.moonbitlang.com/download
- Module configuration: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
- Packages: https://docs.moonbitlang.com/en/stable/language/packages.html
- Current documentation recommends `moon.mod` and `moon.pkg`, replacing legacy JSON manifests.
- The module root is a reusable library; `cmd/main` is an executable example.
- Only the MoonBit core math package is needed. No third-party runtime dependencies.

## Existing projects inspected

- https://github.com/Qix-/color-convert — MIT JavaScript conversion library. Its README documents RGB channels 0–255, HSL degrees and percentages, and rounded/unrounded conversions. Useful API comparison, not a dependency or source-code port.
- https://github.com/lkdrt/moonbit-palette-forge — MoonBit color engine with substantially broader color spaces and palette features. Its public README establishes ecosystem feasibility; implementation was not copied or audited.
- https://github.com/moonbitlang/office.mbt — spreadsheet library whose README lists RGB/HSL utilities; another example of MoonBit suitability for numeric color processing.

## Normative algorithm sources

- https://www.w3.org/TR/css-color-4/#the-hsl-notation — HSL conversion model.
- https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum — sRGB linearization (0.04045 breakpoint), luminance weights, contrast formula, AA text thresholds.
- https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced — AAA text thresholds.

The MVP independently implements these standard formulas in MoonBit. It is not a port of another library. References are background sources, not vendored code. The MIT license applies to this repository's implementation.

## Scope decisions

Opaque 8-bit sRGB only. HEX accepts exactly three or six ASCII hex digits with an optional leading `#`; no whitespace, alpha, CSS names, or CSS function parsing. HSL uses finite hue in [0, 360] and saturation/lightness percentages in [0, 100]; 360 normalizes to zero. RGB output rounds to nearest integer. Basic accessibility means text contrast thresholds, not a full WCAG conformance audit.
