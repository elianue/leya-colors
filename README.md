# Leya Colors

[![MoonBit CI](https://github.com/elianue/leya-colors/actions/workflows/ci.yml/badge.svg)](https://github.com/elianue/leya-colors/actions/workflows/ci.yml)

A lightweight color utility library written in **MoonBit**: validated opaque sRGB colors, HEX/RGB/HSL conversion, relative luminance, and WCAG text contrast checks. No third-party dependencies beyond MoonBit core.

Latest registry release: 0.2.0. The GitHub checkout also includes the unreleased shared-token check below. Created and maintained by Leya (`elianue`), with AI-assisted development. The original planning README is preserved in [docs/README.original.md](docs/README.original.md).

## A real UI decision: one caption color for two card states

When a card flips from a white background to a pink selected state, checking
the caption only on white can let unreadable text ship. Leya Colors checks
the **same** text color on every specified background and selects the first
passing color from the designer-approved list. If none passes, it reports
which uses failed instead of making up a new color.

```sh
moon run cmd/shared-token
```

For this example, `#767676` passes on white (4.54:1) but fails on pink
(3.86:1). The approved plum `#6B5163` passes both (7.04:1 and 5.99:1).
[Same-scenario comparison with Palette Forge](docs/POSITIONING.md#same-scenario-comparison)
shows how to reuse its color output and where Leya Colors adds a
multi-state, approved-palette release check.

## Quick start

Install the current stable [MoonBit toolchain](https://www.moonbitlang.com/download). Tested on Windows x86-64 with `moon 0.1.20261119` and `moonc v0.10.22+124d61d05`. This project uses current `moon.mod` and `moon.pkg` manifests.

```sh
git clone https://github.com/elianue/leya-colors.git
cd leya-colors
moon check
moon test
moon run cmd/main
```

The runnable example prints `#336699`, RGB `(51, 102, 153)`, HSL approximately `(210, 50, 40)`, luminance `0.1250645743288924`, contrast against white `5.997786839657083`, and AA normal-text result `true`.

## Install from Mooncakes

In an existing MoonBit module, add the released library:

```sh
moon add elianue/leya-colors@0.2.0
```

Import the package in the consuming `moon.pkg`:

```moonbit
import {
  "elianue/leya-colors" @colors,
}
```

Then call the API shown below and run `moon check` or `moon test` to fetch and compile the dependency. Registry module: [elianue/leya-colors](https://mooncakes.io/docs/elianue/leya-colors).

### Develop against a local checkout

For a local consumer, arrange sibling directories `my-app/` and `leya-colors/`. In `my-app/moon.work`, list both modules:

```moonbit
members = [ ".", "../leya-colors" ]
```

Add this dependency to `my-app/moon.mod` (the workspace resolves the local source instead of the registry):

```moonbit
import {
  "elianue/leya-colors@0.2.0",
}
```

Add this package import to the consumer's `moon.pkg`:

```moonbit
import {
  "elianue/leya-colors" @colors,
}
```

## Usage

```moonbit
let color = @colors.from_hex("#369").unwrap() // Known-valid literal
let (r, g, b) = color.channels()             // (51, 102, 153)
let hex = color.to_hex()                     // "#336699"
let hsl = color.to_hsl()
let original = hsl.to_rgb()
let white = @colors.rgb(255, 255, 255).unwrap()
let ratio = @colors.contrast_ratio(color, white)
let readable = @colors.passes_contrast(color, white, @colors.AA, @colors.Normal)
```

Handle untrusted input with `Result`, rather than `unwrap()`:

```moonbit
match @colors.from_hex(user_input) {
  Ok(color) => println(color.to_hex())
  Err(@colors.InvalidHex) => println("Expected 3 or 6 hexadecimal digits")
  Err(_) => println("Invalid color")
}
```

See [cmd/main/main.mbt](cmd/main/main.mbt) for a complete runnable example.

A separate consuming module is included in [examples/consumer](examples/consumer). It imports the public package through `moon.work`, checks design tokens, and handles malformed input without panicking:

```sh
cd examples/consumer
moon check
moon test
moon run .
```

The workspace test command runs both the library and consumer tests. The output includes a passing `#336699` token, a failing `#777777` token, and a handled invalid input. Return to the repository root before running the library-only commands below. This example is excluded from the library publication archive.

## API and validation

| API | Behavior |
| --- | --- |
| `rgb(r, g, b)` | `Result[Rgb, ColorError]`; integer channels 0–255 |
| `hsl(h, s, l)` | `Result[Hsl, ColorError]`; degrees 0–360, percentages 0–100 |
| `from_hex(text)` | `Result[Rgb, ColorError]`; 3 or 6 ASCII hex digits, optional hash |
| `hex_to_hsl(text)` | HEX directly to `Result[Hsl, ColorError]` |
| `Rgb::channels()` | `(Int, Int, Int)` |
| `Rgb::to_hex()` | Canonical uppercase `#RRGGBB` |
| `Rgb::to_hsl()` | HSL with fractional precision retained |
| `Hsl::components()` | `(Double, Double, Double)` degrees/percent/percent |
| `Hsl::to_rgb()` / `to_hex()` | RGB rounded to the nearest integer |
| `Rgb::relative_luminance()` | Double in 0–1 |
| `contrast_ratio(a, b)` | Symmetric ratio in 1–21 |
| `required_contrast(level, size)` | Required text contrast ratio |
| `passes_contrast(a, b, level, size)` | Compare the unrounded ratio to its threshold |

`ColorError` has `InvalidRgb`, `InvalidHsl`, and `InvalidHex` variants. Color fields are private; use constructors and accessors. Inputs are rejected rather than clamped. HSL rejects NaN, infinities and out-of-range values; hue 360 normalizes to 0. Achromatic RGB has hue 0. HEX rejects whitespace, alpha, CSS names and CSS function strings. Floating-point conversions retain ordinary numeric precision; only final RGB output is quantized.

## Accessibility semantics

| Level | Normal text | Large text |
| --- | --- | --- |
| AA | 4.5:1 | 3:1 |
| AAA | 7:1 | 4.5:1 |

Large text means at least 18 pt regular or 14 pt bold under [WCAG 2.2](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum). The caller classifies font size and weight. These functions assess text color contrast only, not overall WCAG conformance, font rendering, gradients, transparency or UI component requirements. No rounding precedes threshold comparisons: 4.478 fails a 4.5 requirement.

Luminance uses the sRGB 0.04045 linearization breakpoint and weights 0.2126, 0.7152, 0.0722. Contrast is `(lighter + 0.05) / (darker + 0.05)`.

## Development

```sh
moon fmt --check
moon check
moon test
moon build
moon run cmd/main
moon info
```

The library currently has **30 tests** per backend. Tests cover standard colors, malformed strings, non-finite values, all six HSL sectors, grayscale, numerical fixtures, 1,000 RGB/HSL/HEX round trips, another 1,000-color validation grid, and contrast invariants over all 256 gray levels. WCAG tests cover adjacent 8-bit grays on both sides of 3, 4.5 and 7, plus exact inclusive thresholds and epsilon neighbors. The separate consumer adds 2 integration tests (32 in its workspace). See [development results](docs/DEVELOPMENT.md).

GitHub Actions runs formatting, checking, Wasm/JavaScript tests, build, and both runnable examples on Ubuntu and Windows for pushes and pull requests. Third-party actions are pinned to commit hashes. The MoonBit channel is `latest` so the CI log records the actual installed versions; the compiler itself is not pinned, and a future language change can require maintenance. There are no publication credentials or deployment steps in CI.

- `color.mbt`: validated types, parsing and conversions
- `contrast.mbt`: luminance and text contrast
- `*_test.mbt`: public API tests
- `cmd/main`: executable example
- `pkg.generated.mbti`: generated public API
- `docs/RESEARCH.md`: feasibility, standards and related projects

## References and remaining work

An independent implementation of standard formulas, not a source-code port. Related projects inspected: [color-convert](https://github.com/Qix-/color-convert), [MoonBit Palette Forge](https://github.com/lkdrt/moonbit-palette-forge), and [office.mbt](https://github.com/moonbitlang/office.mbt). See [research notes](docs/RESEARCH.md).

CSS functional parsing/names, perceptual color spaces and a visual UI remain outside this library. No competition application is included.

## License

[MIT](LICENSE).

## Expanded color toolkit (main branch)

The checkout now includes HSV conversion, RGBA hex parsing and source-over
composition, sRGB/linear-light mixing, gradients, harmony palettes, contrast
selection and multi-stop gradients. These additions are included in version 0.2.0.

- `hsv(h,s,v)`, `Rgb::to_hsv`, `Hsv::to_rgb/to_hsl/to_hex`, `Hsl::to_hsv`.
- `rgba(r,g,b,a)`, `Rgb::with_alpha`, `from_hex_alpha`, `Rgba::over/flatten/to_hex/components`, `alpha_contrast`.
- `mix(a,b,amount,space)`, `gradient(a,b,count,space)` with `Srgb` or `LinearRgb`.
- `Rgb::tint/shade/rotate_hue/complement/triadic/analogous/adjust_saturation/adjust_lightness`.
- `best_foreground`, `readable_foregrounds`, `audit_palette`.
- `color_stop`, `sample_stops`, `gradient_stops`, `suggest_foreground`.

Additional errors are `InvalidHsv`, `InvalidAlpha`, `InvalidAmount`, and
`InvalidCount`. HSV uses degrees and percentages; alpha and mix amounts use
0..1. NaN/infinities are rejected. Gradient counts are 1..4096; a singleton
contains the start color. Audits and multi-stop gradients accept at most 256
entries. Stops must be strictly ordered with endpoints at 0 and 1.
Alpha hex uses RGBA/RRGGBBAA; the original `from_hex` remains RGB-only.
Composition uses encoded sRGB and rounds each result to 8-bit channels.
`suggest_foreground` returns the best black/white fallback if a requested
contrast cannot be reached; always check the returned color with
`passes_contrast`. It does not minimize perceptual distance.

See [resubmission evidence and source counts](docs/RESUBMISSION.md).
Run `powershell -File scripts/count-source.ps1` to reproduce the core source
count: 696 code lines, or 548 after also excluding delimiter-only lines.
Both counts exclude tests, examples, generated interfaces and comments.

## Check a real design-token workflow

Run `moon run cmd/audit` to parse named UI tokens, measure contrast, suggest
corrections and report unreachable targets. For AA normal text on white,
`#777777` (4.478:1) becomes `#767676` (4.542:1); `#336699` is preserved.
Malformed input is reported and skipped. AAA normal text on `#777777`
reports failure explicitly.

Prefer `suggest_contrast(original, background, level, size)` for new callers.
Its `ContrastSuggestion` exposes `color`, `ratio`, `required`, `passes`, and
`changed`. The original `suggest_foreground` remains available for compatibility.
See [scope, ecosystem comparison and independent validation](docs/POSITIONING.md).
