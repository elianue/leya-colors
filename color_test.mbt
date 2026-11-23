///|
fn close(a : Double, b : Double) -> Bool {
  (a - b).abs() < 0.000000001
}

///|
test "HSL outputs can always be reconstructed with the validating constructor" {
  for r in [0, 1, 2, 10, 11, 127, 128, 253, 254, 255] {
    for g in [0, 1, 2, 10, 11, 127, 128, 253, 254, 255] {
      for b in [0, 1, 2, 10, 11, 127, 128, 253, 254, 255] {
        let color = @colors.rgb(r, g, b).unwrap()
        let (h, s, l) = color.to_hsl().components()
        assert_true(h >= 0.0 && h < 360.0)
        assert_true(s >= 0.0 && s <= 100.0)
        assert_true(l >= 0.0 && l <= 100.0)
        assert_eq(@colors.hsl(h, s, l).unwrap().to_rgb(), color)
      }
    }
  }
}

///|
test "hex accepts short, long, case and optional hash" {
  assert_eq(@colors.from_hex("#aBc"), @colors.rgb(170, 187, 204))
  assert_eq(@colors.from_hex("ABC"), @colors.rgb(170, 187, 204))
  assert_eq(@colors.from_hex("#123456"), @colors.rgb(18, 52, 86))
  assert_eq(@colors.from_hex("00ff80"), @colors.rgb(0, 255, 128))
  assert_eq(@colors.from_hex("#abc").unwrap().to_hex(), "#AABBCC")
}

///|
test "hex rejects malformed strings and alpha" {
  for
    text in [
      "", "#", "12", "1234", "12345", "1234567", "12345678", "##abc", "#ggg", " #abc",
      "#abc ", "#１２３", "#😀ab",
    ] {
    assert_eq(@colors.from_hex(text), Err(@colors.InvalidHex))
  }
}

///|
test "RGB validation and channels" {
  assert_eq(@colors.rgb(0, 255, 1).unwrap().channels(), (0, 255, 1))
  for
    (r, g, b) in [
      (-1, 0, 0),
      (256, 0, 0),
      (0, -1, 0),
      (0, 256, 0),
      (0, 0, -1),
      (0, 0, 256),
    ] {
    assert_eq(@colors.rgb(r, g, b), Err(@colors.InvalidRgb))
  }
}

///|
test "HSL validates ranges and non-finite inputs" {
  assert_eq(@colors.hsl(360.0, 100.0, 50.0), @colors.hsl(0.0, 100.0, 50.0))
  let nan = 0.0 / 0.0
  let inf = 1.0 / 0.0
  for
    (h, s, l) in [
      (-1.0, 0.0, 0.0),
      (361.0, 0.0, 0.0),
      (0.0, -1.0, 0.0),
      (0.0, 101.0, 0.0),
      (0.0, 0.0, -1.0),
      (0.0, 0.0, 101.0),
      (nan, 0.0, 0.0),
      (0.0, nan, 0.0),
      (0.0, 0.0, nan),
      (inf, 0.0, 0.0),
      (0.0, inf, 0.0),
      (0.0, 0.0, inf),
      (-inf, 0.0, 0.0),
    ] {
    assert_eq(@colors.hsl(h, s, l), Err(@colors.InvalidHsl))
  }
}

///|
test "HSL primary and secondary colors" {
  for
    (hex, hue) in [
      ("#FF0000", 0.0),
      ("#FFFF00", 60.0),
      ("#00FF00", 120.0),
      ("#00FFFF", 180.0),
      ("#0000FF", 240.0),
      ("#FF00FF", 300.0),
    ] {
    let color = @colors.from_hex(hex).unwrap()
    assert_eq(color.to_hsl().components(), (hue, 100.0, 50.0))
    assert_eq(@colors.hsl(hue, 100.0, 50.0).unwrap().to_rgb(), color)
  }
}

///|
test "achromatic endpoints and fractional rounding" {
  assert_eq(@colors.hsl(120.0, 0.0, 50.0).unwrap().to_hex(), "#808080")
  assert_eq(@colors.hsl(55.0, 100.0, 0.0).unwrap().to_hex(), "#000000")
  assert_eq(@colors.hsl(55.0, 100.0, 100.0).unwrap().to_hex(), "#FFFFFF")
  assert_eq(@colors.rgb(128, 128, 128).unwrap().to_hsl().components().0, 0.0)
  assert_eq(@colors.hex_to_hsl("bad!"), Err(@colors.InvalidHex))
  assert_eq(@colors.hex_to_hsl("#F00"), @colors.hsl(0.0, 100.0, 50.0))
}

///|
test "RGB HSL and HEX round trips on a deterministic grid" {
  for r in [0, 1, 10, 11, 64, 127, 128, 192, 254, 255] {
    for g in [0, 1, 10, 11, 64, 127, 128, 192, 254, 255] {
      for b in [0, 1, 10, 11, 64, 127, 128, 192, 254, 255] {
        let color = @colors.rgb(r, g, b).unwrap()
        assert_eq(color.to_hsl().to_rgb(), color)
        assert_eq(@colors.from_hex(color.to_hex()), Ok(color))
      }
    }
  }
}

///|
test "non-primary HSL independently calculated fixture" {
  let (h, s, l) = @colors.rgb(140, 200, 100).unwrap().to_hsl().components()
  assert_true(close(h, 96.0))
  assert_true(close(s, 47.61904761904762))
  assert_true(close(l, 58.82352941176471))
  assert_eq(
    @colors.hsl(96.0, 47.61904761904762, 58.82352941176471).unwrap().to_rgb(),
    @colors.rgb(140, 200, 100).unwrap(),
  )
}
