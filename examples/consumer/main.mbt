// A separate module consuming only the public API through a local workspace.

///|
fn main {
  let background = @colors.from_hex("#FFFFFF").unwrap()
  for input in ["#336699", "#777", "invalid"] {
    match @colors.from_hex(input) {
      Err(_) => println("\{input}: invalid HEX; expected 3 or 6 digits")
      Ok(foreground) => {
        let ratio = @colors.contrast_ratio(foreground, background)
        let passes = @colors.passes_contrast(
          foreground,
          background,
          @colors.AA,
          @colors.Normal,
        )
        println(
          "\{foreground.to_hex()}: contrast=\{ratio}, AA normal=\{passes}",
        )
      }
    }
  }
}
