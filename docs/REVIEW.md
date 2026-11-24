# Follow-up engineering review

Reviewed 2026-11-23 against repository history and the current official event site. This file is an engineering status record, not a competition application.

## Baseline and findings

The remote main branch initially had 6 commits, including the two pre-implementation README commits. Baseline `moon check`, `moon test` (14 passing tests), and `moon build` succeeded. The formulas for WCAG luminance and text thresholds matched the documented standards. Existing validation already rejected malformed HEX, out-of-range RGB/HSL, NaN and infinities.

One numerical bug was reproduced by a new test: normalizing channel values before calculating HSL chroma allowed saturation to exceed 100 by floating-point error near black/white. Such HSL values could not be reconstructed through the public validating constructor. Extrema/chroma now use integer channel units before converting to Double; a 1,000-color grid checks output bounds and constructor round trips. No clamping or loss of input validation was introduced.

WCAG coverage previously checked 4.5 but did not exercise adjacent gray values around all thresholds or exact inclusive equality. New tests cover white against 148/149 for 3, 118/119 for 4.5, and 89/90 for 7, in both foreground/background orders. A private comparison helper allows testing threshold equality and ±1e-9 without pretending arbitrary luminance is representable in opaque 8-bit RGB. The public API is unchanged.

## Reuse and automation

`examples/consumer` is a separate module with a local `moon.work`, not just another package inside the library. Its example consumes the public API, reports passing/failing design tokens, and handles malformed input. Two integration tests exercise valid and invalid inputs. It is excluded from publication archives.

`.github/workflows/ci.yml` checks formatting, types, Wasm and JavaScript tests, builds and runs examples on Ubuntu/Windows. Action implementations are pinned to inspected commit hashes. The MoonBit `latest` channel intentionally detects toolchain compatibility changes and records the resolved version. CI needs only read access to repository contents.

## Actual local output summary

Toolchain unchanged: `moon 0.1.20261119`, `moonc v0.10.22+124d61d05`, Windows x86-64.

```text
moon fmt --check: Finished.
moon check: Finished. (no warnings or errors)
moon test: Total tests: 17, passed: 17, failed: 0.
moon test --target js: Total tests: 17, passed: 17, failed: 0.
moon build: elianue/leya-colors/cmd/main wasm .../main.wasm
consumer moon test: Total tests: 19, passed: 19, failed: 0.
```

The root example now prints HSL `210, 50%, 40%`; its luminance/contrast remain `0.1250645743288924` and `5.997786839657083`. Consumer output includes AA=true for `#336699`, AA=false for `#777777`, and a handled invalid HEX message.

## Remaining limits

No alpha/compositing, CSS named/functional colors, perceptual color spaces, visual UI or performance benchmarks. Current tests sample conversion round trips rather than exhaustively testing all 16,777,216 RGB colors. HSL-to-RGB deliberately quantizes to 8-bit channels. Native/LLVM backends remain untested. Basic text contrast does not certify overall WCAG compliance. Compared with existing MoonBit color libraries, this project's differentiator is a small validated API and focused regression/integration coverage; a significant ecosystem innovation has not been demonstrated. Registry installation instructions have subsequently been added to the root README.

## Event requirements and gaps

Verified sources:
- https://moonbitlang.github.io/Hackathon2026/
- https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx (the site's current source)

The current site requires a public repository with ongoing substantive development, MoonBit as the main language, clear README, runnable examples and necessary tests. Those technical artifacts are present. It also calls for a one-page project description, actual registration/review, joining the event group and using the GitHub ID as the nickname. These administrative steps and organizer acceptance cannot be verified from this repository. Participants must understand and explain AI-assisted work. The site currently defers November deadlines to official notices; it does not confirm the previously mentioned November 30 deadline.

Earlier conversation screenshots were described as requiring at least 10 meaningful commits, a one-page Markdown application with three complete scenarios, and no AI-written application. Those specific screenshot requirements were not independently revalidated from the current website. Commit count alone cannot establish eligibility: the organizers decide whether each commit and the project meet their requirements. The original two commits are README work, not feature implementations. No history has been rewritten to inflate counts, and no application has been written here.
