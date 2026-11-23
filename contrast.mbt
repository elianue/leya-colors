///|
/// WCAG text contrast level.
#derive(Eq, Debug)
pub(all) enum Level {
  AA
  AAA
}

///|
/// Caller must classify font size/weight; see README for WCAG large text.
#derive(Eq, Debug)
pub(all) enum TextSize {
  Normal
  Large
}

///|
fn linear_channel(channel : Int32) -> Double {
  let s = channel.to_double() / 255.0
  if s <= 0.04045 {
    s / 12.92
  } else {
    @math.pow((s + 0.055) / 1.055, 2.4)
  }
}

///|
/// WCAG relative luminance for opaque sRGB, in [0,1].
pub fn Rgb::relative_luminance(self : Rgb) -> Double {
  let (r, g, b) = self.channels()
  0.2126 * linear_channel(r) +
  0.7152 * linear_channel(g) +
  0.0722 * linear_channel(b)
}

///|
/// Symmetric WCAG contrast ratio, in [1,21]. No rounding before comparison.
pub fn contrast_ratio(a : Rgb, b : Rgb) -> Double {
  let l1 = a.relative_luminance()
  let l2 = b.relative_luminance()
  (@cmp.maximum(l1, l2) + 0.05) / (@cmp.minimum(l1, l2) + 0.05)
}

///|
/// Required text contrast ratio: AA normal 4.5, AA large 3, AAA normal 7, AAA large 4.5.
pub fn required_contrast(level : Level, size : TextSize) -> Double {
  match (level, size) {
    (AA, Normal) => 4.5
    (AA, Large) => 3.0
    (AAA, Normal) => 7.0
    (AAA, Large) => 4.5
  }
}

///|
/// Evaluate only text color contrast, not overall WCAG conformance.
pub fn passes_contrast(
  a : Rgb,
  b : Rgb,
  level : Level,
  size : TextSize,
) -> Bool {
  ratio_passes(contrast_ratio(a, b), level, size)
}

// Keep the inclusive comparison separately testable at exact thresholds:
// opaque 8-bit RGB cannot represent arbitrary luminance values exactly.

///|
fn ratio_passes(ratio : Double, level : Level, size : TextSize) -> Bool {
  ratio >= required_contrast(level, size)
}
