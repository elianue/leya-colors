///|
fn near(a : Double, b : Double) -> Bool {
  (a - b).abs() < 0.000000001
}

///|
test "adjacent 8-bit grays straddle each WCAG text threshold" {
  let white = @colors.rgb(255, 255, 255).unwrap()
  // Independent sRGB fixtures; ratios are never rounded before comparison.
  for
    (pass_gray, fail_gray, level, size, threshold) in [
      (148, 149, @colors.AA, @colors.Large, 3.0),
      (118, 119, @colors.AA, @colors.Normal, 4.5),
      (118, 119, @colors.AAA, @colors.Large, 4.5),
      (89, 90, @colors.AAA, @colors.Normal, 7.0),
    ] {
    let pass = @colors.rgb(pass_gray, pass_gray, pass_gray).unwrap()
    let fail = @colors.rgb(fail_gray, fail_gray, fail_gray).unwrap()
    assert_true(@colors.contrast_ratio(pass, white) > threshold)
    assert_true(@colors.contrast_ratio(fail, white) < threshold)
    assert_true(@colors.passes_contrast(pass, white, level, size))
    assert_true(@colors.passes_contrast(white, pass, level, size))
    assert_false(@colors.passes_contrast(fail, white, level, size))
    assert_false(@colors.passes_contrast(white, fail, level, size))
  }
}

///|
test "WCAG luminance endpoints and primary weights" {
  assert_true(near(@colors.rgb(0, 0, 0).unwrap().relative_luminance(), 0.0))
  assert_true(
    near(@colors.rgb(255, 255, 255).unwrap().relative_luminance(), 1.0),
  )
  assert_true(
    near(@colors.rgb(255, 0, 0).unwrap().relative_luminance(), 0.2126),
  )
  assert_true(
    near(@colors.rgb(0, 255, 0).unwrap().relative_luminance(), 0.7152),
  )
  assert_true(
    near(@colors.rgb(0, 0, 255).unwrap().relative_luminance(), 0.0722),
  )
}

///|
test "sRGB linearization on either side of breakpoint" {
  assert_true(
    near(
      @colors.rgb(10, 10, 10).unwrap().relative_luminance(),
      0.003035269835488375,
    ),
  )
  assert_true(
    near(
      @colors.rgb(11, 11, 11).unwrap().relative_luminance(),
      0.003346535763899161,
    ),
  )
  assert_true(
    near(
      @colors.rgb(128, 128, 128).unwrap().relative_luminance(),
      0.21586050011389926,
    ),
  )
}

///|
test "contrast endpoints, symmetry and independent fixtures" {
  let black = @colors.from_hex("000").unwrap()
  let white = @colors.from_hex("fff").unwrap()
  assert_true(near(@colors.contrast_ratio(black, white), 21.0))
  assert_true(near(@colors.contrast_ratio(white, black), 21.0))
  assert_true(near(@colors.contrast_ratio(white, white), 1.0))
  assert_true(
    near(
      @colors.contrast_ratio(@colors.from_hex("777").unwrap(), white),
      4.478089453577214,
    ),
  )
  assert_true(
    near(
      @colors.contrast_ratio(@colors.from_hex("f00").unwrap(), white),
      3.9984767707539985,
    ),
  )
}

///|
test "AA and AAA decisions without premature rounding" {
  let white = @colors.from_hex("fff").unwrap()
  let gray = @colors.from_hex("777").unwrap()
  assert_false(@colors.passes_contrast(gray, white, @colors.AA, @colors.Normal))
  assert_true(@colors.passes_contrast(gray, white, @colors.AA, @colors.Large))
  assert_false(
    @colors.passes_contrast(gray, white, @colors.AAA, @colors.Normal),
  )
  assert_false(@colors.passes_contrast(gray, white, @colors.AAA, @colors.Large))
  assert_true(
    @colors.passes_contrast(
      @colors.from_hex("767676").unwrap(),
      white,
      @colors.AA,
      @colors.Normal,
    ),
  )
  let black = @colors.from_hex("000").unwrap()
  for level in [@colors.AA, @colors.AAA] {
    for size in [@colors.Normal, @colors.Large] {
      assert_true(@colors.passes_contrast(black, white, level, size))
      assert_false(@colors.passes_contrast(black, black, level, size))
    }
  }
}

///|
test "all threshold combinations" {
  assert_eq(@colors.required_contrast(@colors.AA, @colors.Normal), 4.5)
  assert_eq(@colors.required_contrast(@colors.AA, @colors.Large), 3.0)
  assert_eq(@colors.required_contrast(@colors.AAA, @colors.Normal), 7.0)
  assert_eq(@colors.required_contrast(@colors.AAA, @colors.Large), 4.5)
}

///|
test "contrast invariants on deterministic colors" {
  let black = @colors.rgb(0, 0, 0).unwrap()
  let mut previous = 0.0
  for n = 0; n < 256; n = n + 1 {
    let c = @colors.rgb(n, n, n).unwrap()
    let luminance = c.relative_luminance()
    assert_true(luminance >= previous && luminance <= 1.0)
    previous = luminance
    let ratio = @colors.contrast_ratio(c, black)
    assert_true(ratio >= 1.0 && ratio <= 21.0)
    assert_true(near(ratio, @colors.contrast_ratio(black, c)))
    assert_eq(@colors.contrast_ratio(c, c), 1.0)
  }
}
