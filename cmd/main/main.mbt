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
      let (hh, ss, vv) = color.to_hsv().components()
      println("HSV: \{hh}, \{ss}%, \{vv}%")
      let overlay = color.with_alpha(0.5).unwrap()
      println("50% overlay on white: \{overlay.flatten(white).to_hex()}")
      let ramp = @colors.gradient(color, white, 5, @colors.LinearRgb).unwrap()
      for swatch in ramp {
        println("Gradient: \{swatch.to_hex()}")
      }
      let suggested = @colors.suggest_foreground(
        color,
        white,
        @colors.AAA,
        @colors.Normal,
      )
      println("Suggested AAA foreground: \{suggested.to_hex()}")
    }
  }
}
