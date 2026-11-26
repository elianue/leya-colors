# Scope and ecosystem comparison

## Same-scenario comparison

**Scenario:** a record-collection UI uses one small caption color for both the
default album card (white, `#FFFFFF`) and its selected state (blush pink,
`#FDE7EF`). This is a runnable reference case, not a claim that another
website has already deployed it. The design handoff limits the text color
to an ordered list: current gray `#777777`, approved gray `#767676`, and
approved plum `#6B5163`. Both states require WCAG AA normal-text contrast
of at least 4.5:1.

| Operation on the same card | HEX actually checked | White | Pink | Workflow result |
| --- | --- | ---: | ---: | --- |
| Existing caption | `#777777` | 4.478 | 3.807 | Fails both |
| Approved neutral | `#767676` | 4.542 | 3.862 | Passes only on white |
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

Run from the repository root:

```sh
moon run cmd/shared-token
bash scripts/compare-palette-forge.sh
```

The second command fetches Palette Forge at
[`4ac93f2`](https://github.com/lkdrt/moonbit-palette-forge/tree/4ac93f263658d0dad50b673f2d09f6811bbf4486)
into a temporary workspace. It needs Bash, Git, network access and MoonBit
(tested with `moon 0.1.20261119`). The example compares that revision's
public `fix_contrast` facade, not every possible Palette Forge workflow.
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
