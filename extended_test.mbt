///|
test "multi stop gradients validate ordering and preserve stop colors" {
  let red = @colors.from_hex("#f00").unwrap()
  let green = @colors.from_hex("#0f0").unwrap()
  let blue = @colors.from_hex("#00f").unwrap()
  let start = @colors.color_stop(0.0, red).unwrap()
  let middle = @colors.color_stop(0.25, green).unwrap()
  let end = @colors.color_stop(1.0, blue).unwrap()
  let stops = [start, middle, end]
  assert_eq(middle.components(), (0.25, green))
  assert_eq(@colors.sample_stops(stops, 0.25, @colors.Srgb), Ok(green))
  let ramp = @colors.gradient_stops(stops, 5, @colors.LinearRgb).unwrap()
  assert_eq(ramp[0], red)
  assert_eq(ramp[1], green)
  assert_eq(ramp[4], blue)
  assert_eq(@colors.gradient_stops(stops, 1, @colors.Srgb), Ok([red]))
  for
    invalid in [
      [start, start, end],
      [end, start],
      [middle, end],
      [start, middle],
    ] {
    assert_eq(
      @colors.sample_stops(invalid, 0.5, @colors.Srgb),
      Err(@colors.InvalidAmount),
    )
  }
  assert_eq(
    @colors.sample_stops([], 0.5, @colors.Srgb),
    Err(@colors.InvalidCount),
  )
  assert_eq(
    @colors.sample_stops(stops, -0.1, @colors.Srgb),
    Err(@colors.InvalidAmount),
  )
  assert_eq(@colors.color_stop(0.0 / 0.0, red), Err(@colors.InvalidAmount))
  assert_eq(
    @colors.gradient_stops(stops, 4097, @colors.Srgb),
    Err(@colors.InvalidCount),
  )
}

///|
test "suggest foreground meets feasible targets and exposes impossible AAA" {
  let gray = @colors.from_hex("#777").unwrap()
  for background_hex in ["#fff", "#000", "#369", "#777"] {
    let background = @colors.from_hex(background_hex).unwrap()
    let result = @colors.suggest_foreground(
      gray,
      background,
      @colors.AA,
      @colors.Normal,
    )
    assert_true(
      @colors.passes_contrast(result, background, @colors.AA, @colors.Normal),
    )
    assert_eq(
      @colors.suggest_foreground(result, background, @colors.AA, @colors.Normal),
      result,
    )
  }
  let fallback = @colors.suggest_foreground(
    gray,
    gray,
    @colors.AAA,
    @colors.Normal,
  )
  assert_eq(fallback.to_hex(), "#000000")
  assert_true(
    !@colors.passes_contrast(fallback, gray, @colors.AAA, @colors.Normal),
  )
}

///|
test "HSV primaries sectors and validation" {
  let expected = [
    "#FF0000", "#FFFF00", "#00FF00", "#00FFFF", "#0000FF", "#FF00FF",
  ]
  for i = 0; i < 6; i = i + 1 {
    assert_eq(
      @colors.hsv(i.to_double() * 60.0, 100.0, 100.0).unwrap().to_hex(),
      expected[i],
    )
  }
  assert_eq(@colors.hsv(360.0, 100.0, 100.0).unwrap().to_hex(), "#FF0000")
  for h in [-1.0, 361.0, 0.0 / 0.0, 1.0 / 0.0] {
    assert_eq(@colors.hsv(h, 50.0, 50.0), Err(@colors.InvalidHsv))
  }
  assert_eq(@colors.hsv(0.0, -1.0, 50.0), Err(@colors.InvalidHsv))
  assert_eq(@colors.hsv(0.0, 50.0, 101.0), Err(@colors.InvalidHsv))
}

///|
test "HSV grid round trips including HSL without intermediate quantization" {
  for r in [0, 1, 10, 64, 127, 128, 200, 254, 255] {
    for g in [0, 1, 10, 64, 127, 128, 200, 254, 255] {
      for b in [0, 1, 10, 64, 127, 128, 200, 254, 255] {
        let color = @colors.rgb(r, g, b).unwrap()
        assert_eq(color.to_hsv().to_rgb(), color)
        assert_eq(color.to_hsv().to_hsl().to_rgb(), color)
        assert_eq(color.to_hsl().to_hsv().to_rgb(), color)
      }
    }
  }
}

///|
test "alpha parsing serialization and validation" {
  assert_eq(@colors.from_hex_alpha("#f008").unwrap().to_hex(), "#FF000088")
  for a = 0; a < 256; a = a + 1 {
    let color = @colors.rgba(12, 34, 56, a.to_double() / 255.0).unwrap()
    assert_eq(@colors.from_hex_alpha(color.to_hex()), Ok(color))
  }
  for text in ["", "#abc", "#123456", "#gggg", "#123456789", " #1234"] {
    assert_eq(@colors.from_hex_alpha(text), Err(@colors.InvalidHex))
  }
  for alpha in [-0.1, 1.1, 0.0 / 0.0, 1.0 / 0.0] {
    assert_eq(@colors.rgba(0, 0, 0, alpha), Err(@colors.InvalidAlpha))
  }
  assert_eq(@colors.rgba(-1, 0, 0, 0.5), Err(@colors.InvalidRgb))
}

///|
test "source over numeric fixtures and opaque flattening" {
  let red = @colors.rgba(255, 0, 0, 0.5).unwrap()
  let blue = @colors.rgba(0, 0, 255, 0.5).unwrap()
  assert_eq(red.over(blue).components(), (170, 0, 85, 0.75))
  let white = @colors.rgb(255, 255, 255).unwrap()
  assert_eq(red.flatten(white).to_hex(), "#FF8080")
  let clear = @colors.rgba(255, 99, 1, 0.0).unwrap()
  assert_eq(clear.over(clear).components(), (0, 0, 0, 0.0))
  assert_eq(clear.over(red), red)
  assert_eq(@colors.alpha_contrast(clear, white), 1.0)
  assert_eq(
    @colors.alpha_contrast(red, white),
    @colors.contrast_ratio(red.flatten(white), white),
  )
}

///|
test "mix spaces gradient endpoints and bounds" {
  let black = @colors.rgb(0, 0, 0).unwrap()
  let white = @colors.rgb(255, 255, 255).unwrap()
  assert_eq(
    @colors.mix(black, white, 0.5, @colors.Srgb).unwrap().to_hex(),
    "#808080",
  )
  assert_eq(
    @colors.mix(black, white, 0.5, @colors.LinearRgb).unwrap().to_hex(),
    "#BCBCBC",
  )
  for space in [@colors.Srgb, @colors.LinearRgb] {
    let ramp = @colors.gradient(black, white, 256, space).unwrap()
    assert_eq(ramp[0], black)
    assert_eq(ramp[255], white)
    for i = 1; i < 256; i = i + 1 {
      assert_true(
        ramp[i].relative_luminance() >= ramp[i - 1].relative_luminance(),
      )
    }
    assert_eq(@colors.gradient(black, white, 1, space), Ok([black]))
  }
  for count in [-1, 0, 4097] {
    assert_eq(
      @colors.gradient(black, white, count, @colors.Srgb),
      Err(@colors.InvalidCount),
    )
  }
  for amount in [-0.1, 1.1, 0.0 / 0.0, 1.0 / 0.0] {
    assert_eq(
      @colors.mix(black, white, amount, @colors.Srgb),
      Err(@colors.InvalidAmount),
    )
  }
}

///|
test "harmony and color adjustments" {
  let red = @colors.from_hex("#f00").unwrap()
  assert_eq(red.complement().to_hex(), "#00FFFF")
  let triad = red.triadic()
  assert_eq(triad[1].to_hex(), "#00FF00")
  assert_eq(triad[2].to_hex(), "#0000FF")
  assert_eq(red.rotate_hue(-120.0).unwrap(), triad[2])
  assert_eq(red.rotate_hue(720.0), Ok(red))
  assert_eq(red.analogous(60.0).unwrap()[0].to_hex(), "#FF00FF")
  assert_eq(red.analogous(-1.0), Err(@colors.InvalidAmount))
  assert_eq(red.rotate_hue(1.0 / 0.0), Err(@colors.InvalidAmount))
  assert_eq(red.adjust_saturation(-100.0).unwrap().to_hex(), "#808080")
  assert_eq(red.adjust_lightness(100.0).unwrap().to_hex(), "#FFFFFF")
  assert_eq(red.adjust_lightness(-100.0).unwrap().to_hex(), "#000000")
  assert_eq(red.tint(1.0).unwrap().to_hex(), "#FFFFFF")
  assert_eq(red.shade(1.0).unwrap().to_hex(), "#000000")
}

///|
test "palette audit indices contrast and selection" {
  let black = @colors.from_hex("#000").unwrap()
  let white = @colors.from_hex("#fff").unwrap()
  let gray = @colors.from_hex("#777").unwrap()
  assert_eq(@colors.best_foreground(white, []), None)
  assert_eq(@colors.best_foreground(white, [gray, black]), Some(black))
  assert_eq(
    @colors.readable_foregrounds(
      white,
      [gray, black],
      @colors.AA,
      @colors.Normal,
    ),
    [black],
  )
  let rows = @colors.audit_palette(
    [black, white, gray],
    @colors.AA,
    @colors.Normal,
  ).unwrap()
  assert_eq(rows.length(), 3)
  assert_eq(
    (rows[0].first, rows[0].second, rows[0].ratio, rows[0].passes),
    (0, 1, 21.0, true),
  )
  assert_eq((rows[2].first, rows[2].second, rows[2].passes), (1, 2, false))
  assert_eq(@colors.audit_palette([], @colors.AA, @colors.Normal), Ok([]))
  let many = [black]
  for i = 0; i < 256; i = i + 1 {
    many.push(white)
  }
  assert_eq(
    @colors.audit_palette(many, @colors.AA, @colors.Normal),
    Err(@colors.InvalidCount),
  )
}
