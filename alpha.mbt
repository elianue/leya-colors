///|
/// Straight (unpremultiplied) alpha in [0,1].
#derive(Eq, Debug)
pub struct Rgba {
  priv color : Rgb
  priv alpha : Double
}

///|
pub fn rgba(
  r : Int32,
  g : Int32,
  b : Int32,
  alpha : Double,
) -> Result[Rgba, ColorError] {
  match rgb(r, g, b) {
    Err(e) => Err(e)
    Ok(color) => color.with_alpha(alpha)
  }
}

///|
pub fn Rgb::with_alpha(self : Rgb, alpha : Double) -> Result[Rgba, ColorError] {
  if !(alpha >= 0.0 && alpha <= 1.0) {
    Err(InvalidAlpha)
  } else {
    Ok({ color: self, alpha, })
  }
}

///|
pub fn Rgba::components(self : Rgba) -> (Int32, Int32, Int32, Double) {
  let (r, g, b) = self.color.channels()
  (r, g, b, self.alpha)
}

///|
/// Parse RGBA or RRGGBBAA only; alpha is always the last channel.
pub fn from_hex_alpha(text : String) -> Result[Rgba, ColorError] {
  let start = if text.length() > 0 && text[0] == 35 { 1 } else { 0 }
  let n = text.length() - start
  if n != 4 && n != 8 {
    return Err(InvalidHex)
  }
  let digits : Array[Int32] = []
  for i = start; i < text.length(); i = i + 1 {
    match hex_digit(text[i]) {
      None => return Err(InvalidHex)
      Some(digit) => digits.push(digit)
    }
  }
  if n == 4 {
    rgba(
      digits[0] * 17,
      digits[1] * 17,
      digits[2] * 17,
      digits[3].to_double() / 15.0,
    )
  } else {
    rgba(
      digits[0] * 16 + digits[1],
      digits[2] * 16 + digits[3],
      digits[4] * 16 + digits[5],
      (digits[6] * 16 + digits[7]).to_double() / 255.0,
    )
  }
}

///|
pub fn Rgba::to_hex(self : Rgba) -> String {
  self.color.to_hex() + hex_byte((self.alpha * 255.0 + 0.5).to_int())
}

///|
/// Porter-Duff source-over using encoded sRGB channel arithmetic.
/// Channels are rounded to 8 bits after each composition.
pub fn Rgba::over(self : Rgba, background : Rgba) -> Rgba {
  let alpha = self.alpha + background.alpha * (1.0 - self.alpha)
  if alpha == 0.0 {
    return rgba(0, 0, 0, 0.0).unwrap()
  }
  let (sr, sg, sb) = self.color.channels()
  let (br, bg, bb) = background.color.channels()
  let weight = background.alpha * (1.0 - self.alpha)
  fn channel(
    s : Int32,
    b : Int32,
    sa : Double,
    w : Double,
    a : Double,
  ) -> Int32 {
    ((s.to_double() * sa + b.to_double() * w) / a + 0.5).to_int()
  }
  rgba(
    channel(sr, br, self.alpha, weight, alpha),
    channel(sg, bg, self.alpha, weight, alpha),
    channel(sb, bb, self.alpha, weight, alpha),
    alpha,
  ).unwrap()
}

///|
/// Flatten onto an opaque background before computing contrast.
pub fn Rgba::flatten(self : Rgba, background : Rgb) -> Rgb {
  self.over(background.with_alpha(1.0).unwrap()).color
}

///|
pub fn alpha_contrast(foreground : Rgba, background : Rgb) -> Double {
  contrast_ratio(foreground.flatten(background), background)
}
