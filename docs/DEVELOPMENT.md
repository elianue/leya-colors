# MVP development record

## Implemented

- Pure MoonBit core implementation, opaque validated `Rgb` and `Hsl` types.
- Short/long HEX parsing, RGB/HEX/HSL conversions, deterministic rounding.
- Range validation, non-finite HSL rejection, typed errors.
- WCAG sRGB relative luminance and symmetric contrast ratio.
- AA/AAA checks for normal/large text, using unrounded contrast values.
- Executable usage example, English README, generated API and MIT license.
- Original README preserved verbatim in `docs/README.original.md`.

## Actual local verification

Toolchain: official latest stable archive retrieved during development, `moon 0.1.20261119 (738607b)`, `moonc v0.10.22+124d61d05`, standard library `0.10.22+124d61d05`, Windows x86-64. Archive SHA-256 matched the official value: `8e552848a5c06dcce6bab725687562a689397948b7144e9087e9ffa4c1d38be4`.

| Command | Observed result |
| --- | --- |
| `moon fmt --check` | Passed |
| `moon check` | Passed, no warnings or errors |
| `moon test` | 14 tests passed, 0 failed (default Wasm backend) |
| `moon test --target js` | 14 tests passed, 0 failed (Node v24.16.0) |
| `moon build` | Passed; example Wasm artifact built |
| `moon run cmd/main` | Passed; output below |
| `moon info` | Generated `pkg.generated.mbti` |
| Separate consumer via `moon.work` | Built and ran successfully using only the public package API |
| `moon package --list` | Package built; local toolchain excluded from distributable files |

```text
HEX: #336699
RGB: 51, 102, 153
HSL: 210, 49.99999999999999%, 40%
Luminance: 0.1250645743288924
Contrast against white: 5.997786839657083
AA normal text: true
```

Eight conversion tests include a deterministic 1,000-color grid with exact RGB recovery after HSL and HEX round trips. Six contrast tests include independently calculated numeric fixtures, all four text thresholds, rejection of rounded-up 4.478 contrast for AA normal text, and monotonic luminance/contrast invariants across all 256 grayscale values. Test counts refer to test blocks, not individual assertions.

## Meaningful development stages

1. Project manifests, license, preservation of existing README, feasibility research.
2. Validated color types and conversions with passing conversion tests.
3. WCAG formulas and text contrast checks with passing reference tests.
4. Runnable example, generated API, English documentation and verification record.

Commits represent completed development stages. No empty commits, duplicate commits, or arbitrary commit-count target.

## Limitations / unfinished

- No alpha blending, CSS functional syntax/names, perceptual color spaces or palette generation.
- No visual interface, browser integration or automated classification of text sizes.
- Contrast helpers do not certify complete WCAG compliance.
- No mooncakes.io publication or tagged release yet.
- Native/LLVM backends and other operating systems have not been tested.
- No competition application has been written.

See [RESEARCH.md](RESEARCH.md) for standards, related open-source projects and implementation provenance.
