# Scope and ecosystem comparison

Reviewed 2026-11-25 against the related project's public README. This is a
feature-scope comparison, not a performance benchmark or an implementation audit.

| Need | Leya Colors | Palette Forge (documented scope) |
| --- | --- | --- |
| RGB/HSL/HSV and validated inputs | Supported | Supported |
| Text contrast and remediation | WCAG ratios and discrete black/white-path search | WCAG/APCA audits and remediation |
| Perceptual color spaces | Not supported | Lab, OkLab, OkLCH and others |
| Semantic themes and export formats | Not supported | Themes, aliases and multiple export formats |
| Focus | Small single-package color API and reproducible token-check example | Broad design-system color engine |

Source: [Palette Forge README](https://github.com/lkdrt/moonbit-palette-forge).
The comparison confirms overlap; Leya Colors does not claim that color
conversion, validation or accessibility auditing are new ecosystem capabilities.
Choose it when a small API with explicit numeric contracts is sufficient.
Evaluate Palette Forge when perceptual interpolation, themes or export formats
are needed. No speed or memory advantage has been measured here.

## Reproducible use case

Run `moon run cmd/audit`. The example checks named UI tokens against white:

1. `body` (#336699) already passes AA normal text and is preserved.
2. `muted` (#777777) fails 4.5:1 and receives a measured passing suggestion.
3. A malformed token is reported and skipped without panicking.
4. AAA normal text on #777777 demonstrates an unreachable target: the result
   reports `passes=false` rather than promising an accessible replacement.

`suggest_contrast` returns `color`, `ratio`, `required`, `passes`, and `changed`.
The search changes encoded sRGB channels toward black/white in 255 steps; it
does not minimize perceptual distance. An impossible target may require a
different background or typography classification. The program demonstrates
text-contrast decisions, not complete WCAG compliance.

## Independent numeric checks

`reference_test.mbt` uses primary-color luminance weights directly, manually
computed HSV chroma/sector fixtures and a fractional Porter-Duff composition
fixture. Expected constants do not call the implementation under test. This
complements conversion round trips, which alone could hide paired mistakes.

Luminance/contrast basis: [WCAG contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum).
Composition basis: [W3C source-over compositing](https://www.w3.org/TR/compositing-1/#porterduffcompositingoperators_srcover).
