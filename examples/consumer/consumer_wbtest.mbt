///|
test "consumer handles malformed input without panicking" {
  assert_eq(@colors.from_hex("invalid"), Err(@colors.InvalidHex))
  assert_eq(@colors.rgb(256, 0, 0), Err(@colors.InvalidRgb))
}

///|
test "consumer checks design tokens against a background" {
  let background = @colors.from_hex("#FFF").unwrap()
  let text = @colors.from_hex("#336699").unwrap()
  assert_true(
    @colors.passes_contrast(text, background, @colors.AA, @colors.Normal),
  )
  assert_eq(text.to_hsl().to_hex(), "#336699")
  assert_false(
    @colors.passes_contrast(
      @colors.from_hex("#777").unwrap(),
      background,
      @colors.AA,
      @colors.Normal,
    ),
  )
}
