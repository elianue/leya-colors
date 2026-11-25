///|
/// Reproducible design-token audit: parse, measure, suggest, verify.
fn main {
  let background = @colors.from_hex("#FFFFFF").unwrap()
  for
    (name, text) in [
      ("body", "#336699"),
      ("muted", "#777777"),
      ("invalid", "#oops"),
    ] {
    match @colors.from_hex(text) {
      Err(_) => println("\{name}: invalid HEX \{text}; skipped")
      Ok(color) => {
        let result = @colors.suggest_contrast(
          color,
          background,
          @colors.AA,
          @colors.Normal,
        )
        println(
          "\{name}: \{color.to_hex()} ratio=\{@colors.contrast_ratio(color, background)}",
        )
        println(
          "  suggested=\{result.color.to_hex()} ratio=\{result.ratio} required=\{result.required} passes=\{result.passes} changed=\{result.changed}",
        )
      }
    }
  }
  let gray = @colors.from_hex("#777777").unwrap()
  let impossible = @colors.suggest_contrast(
    gray,
    gray,
    @colors.AAA,
    @colors.Normal,
  )
  println(
    "AAA on gray: best=\{impossible.color.to_hex()} ratio=\{impossible.ratio} passes=\{impossible.passes}",
  )
  if !impossible.passes {
    println(
      "  Change the background or typography requirement; this foreground search cannot reach 7:1.",
    )
  }
}
