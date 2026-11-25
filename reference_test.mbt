///|
fn near_reference(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() < 0.000000001
}

///|
test "independent primary luminance and WCAG contrast fixtures" {
  // CSS sRGB primary channels linearize exactly to 0 or 1. Expected values
  // use the WCAG weights directly, not another call to library conversion.
  for
    (hex, luminance, on_black) in [
      ("#FF0000", 0.2126, 5.252),
      ("#00FF00", 0.7152, 15.304),
      ("#0000FF", 0.0722, 2.444),
      ("#FFFF00", 0.9278, 19.556),
    ] {
    let color = @colors.from_hex(hex).unwrap()
    assert_true(near_reference(color.relative_luminance(), luminance))
    assert_true(
      near_reference(
        @colors.contrast_ratio(color, @colors.rgb(0, 0, 0).unwrap()),
        on_black,
      ),
    )
  }
}

///|
test "HSV nonprimary fixtures computed from chroma and sector formulas" {
  for
    (h, s, v, expected) in [
      (30.0, 100.0, 100.0, "#FF8000"),
      (210.0, 50.0, 80.0, "#6699CC"),
      (270.0, 100.0, 50.0, "#400080"),
      (0.0, 0.0, 20.0, "#333333"),
    ] {
    assert_eq(@colors.hsv(h, s, v).unwrap().to_hex(), expected)
  }
}

///|
test "source over independent fractional alpha fixture" {
  // a=1/4 + (1/2)*(3/4)=5/8; normalized weights are 2/5 and 3/5.
  let source = @colors.rgba(200, 100, 0, 0.25).unwrap()
  let backdrop = @colors.rgba(0, 100, 200, 0.5).unwrap()
  assert_eq(source.over(backdrop).components(), (80, 100, 120, 0.625))
}

///|
test "suggestion reports unchanged corrected and unreachable results" {
  let white = @colors.from_hex("#fff").unwrap()
  let black = @colors.from_hex("#000").unwrap()
  let gray = @colors.from_hex("#777").unwrap()
  let unchanged = @colors.suggest_contrast(
    black,
    white,
    @colors.AA,
    @colors.Normal,
  )
  assert_eq(
    (
      unchanged.color,
      unchanged.ratio,
      unchanged.required,
      unchanged.passes,
      unchanged.changed,
    ),
    (black, 21.0, 4.5, true, false),
  )
  let fixed = @colors.suggest_contrast(gray, white, @colors.AA, @colors.Normal)
  assert_true(fixed.passes && fixed.changed && fixed.ratio >= fixed.required)
  let impossible = @colors.suggest_contrast(
    gray,
    gray,
    @colors.AAA,
    @colors.Normal,
  )
  assert_eq(impossible.color, black)
  assert_true(!impossible.passes && impossible.ratio < impossible.required)
}
