///|
fn main {
  match @colors.from_hex("#336699") {
    Err(_) => println("Invalid HEX color")
    Ok(color) => {
      println("HEX: \{color.to_hex()}")
      let (r, g, b) = color.channels()
      println("RGB: \{r}, \{g}, \{b}")
      let (h, s, l) = color.to_hsl().components()
      println("HSL: \{h}, \{s}%, \{l}%")
      let white = @colors.rgb(255, 255, 255).unwrap()
      println("Luminance: \{color.relative_luminance()}")
      println("Contrast against white: \{@colors.contrast_ratio(color, white)}")
      println(
        "AA normal text: \{@colors.passes_contrast(color, white, @colors.AA, @colors.Normal)}",
      )
    }
  }
}
