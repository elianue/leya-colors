# Scope and ecosystem comparison

## Same-scenario comparison

**Scenario:** a record-collection UI uses one small caption color for both the
default album card (white, `#FFFFFF`) and its selected state (blush pink,
`#FDE7EF`). This is a runnable reference case, not a claim that another
website has already deployed it. The design handoff limits the text color
to an ordered list: current gray `#777777`, approved gray `#767676`, and
approved plum `#6B5163`. Both states require WCAG AA normal-text contrast
of at least 4.5:1.

### Why one token across both states?

This reference component has a shared `card.caption.foreground` token; selection
changes `card.background` and adds a selected marker, while caption text keeps
its identity. A background-only state change is a common component contract;
checking the foreground only on the default background misses its selected use.
The handoff deliberately treats the foreground token as one approved value,
so the release check must quantify over both uses rather than repair each pair
independently. A designer is free to change that contract and introduce a
separate selected-state foreground; this library does not prohibit that design.

In this illustrative handoff the preference is: retain the existing neutral,
then use its approved neutral adjustment, then use the approved plum accent.
The list represents an explicit design input, not a palette invented by the
checker. The exact colors are fixtures, not evidence of a customer's approval.
There is no claim of a deployed consumer or external user study. The concrete
deliverable is an executable component contract with per-use failure evidence.

| Operation on the same card | HEX actually checked | White | Pink | Workflow result |
| --- | --- | ---: | ---: | --- |
| Existing caption | `#777777` | 4.478 | 3.807 | Fails both |
| Approved neutral | `#767676` | 4.542 | 3.862 | Passes only on white |
| Palette Forge measurements plus the same approved-candidate selection policy | `#6B5163` | 7.042 | 5.986 | Same choice as Leya Colors |
| Palette Forge's single-background fix called with white | `#777777` | 4.478 | 3.807 | Recheck the emitted HEX; it does not pass in this run |
| Palette Forge's single-background fix called with pink | `#6B6B6B` | 5.329 | 4.531 | Passes both, but is outside this approved list |
| Leya Colors' first approved candidate passing both states | `#6B5163` | 7.042 | 5.986 | Use the same color for both cards |

Ratios are displayed to three decimals here; neither decision uses rounded
ratios. The example measures the Palette Forge colors *after* serializing
to HEX, because that is what the UI would ship.

### What is reused, and what is different?

[Palette Forge](https://github.com/lkdrt/moonbit-palette-forge) already
covers color conversions, palette and theme generation, and WCAG/APCA
audits. It can supply the palette and background colors. The runnable
comparison takes the same inputs and passes Palette Forge color values to
Leya Colors as HEX, with no integration dependency in the core package.
A developer could implement the same selection policy using Palette Forge's
pairwise measurements. The distinction is the policy exposed directly by
`select_shared_text_token`: preserve the caller's candidate preference,
require **one** approved color to pass **every** declared use, and return
the full set of measurements even when no approved color passes. The
claim is about this workflow, not unique contrast mathematics, greater
accuracy in general, or a performance advantage.

The comparison includes an independent loop over the same approved candidates
using Palette Forge's `check_wcag`, not Leya's contrast function. It checks all
candidate/surface ratios and decisions against Leya and asserts that both
policies select plum. Thus the result demonstrates policy packaging and HEX
interoperability, not an inability of Palette Forge to solve this task. The
single-background correction rows are a separate workflow illustration, not
the baseline for claiming a superior multi-background algorithm.

Run from the repository root:

```sh
moon run cmd/shared-token
bash scripts/compare-palette-forge.sh
```

The second command fetches Palette Forge at
[`4ac93f2`](https://github.com/lkdrt/moonbit-palette-forge/tree/4ac93f263658d0dad50b673f2d09f6811bbf4486)
into a temporary workspace. It needs Bash, Git, network access and MoonBit
(tested with `moon 0.1.20261119`). The example compares that revision's
public `fix_contrast` facade and a same-task policy implemented with its
`check_wcag` measurements. It does not compare every possible upstream workflow.
The program exits unsuccessfully if the pinned correction HEX values, cross-library
measurements, pass/fail decisions or selected token diverge. CI runs it on Ubuntu.
The package tests also cover a no-match handoff, an empty handoff,
different text-size rules, and deterministic candidate preference.
The check is for solid, opaque text/background colors and is not a full
WCAG conformance audit.

## Earlier single-background example

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
