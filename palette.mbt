///|
/// Interpolation in encoded sRGB or linear-light sRGB.
#derive(Eq, Debug)
pub(all) enum MixSpace {
  Srgb
  LinearRgb
}

///|
fn valid_amount(amount : Double) -> Bool {
  amount >= 0.0 && amount <= 1.0
}

///|
fn encode_channel(value : Double) -> Int32 {
  let encoded = if value <= 0.0031308 {
    value * 12.92
  } else {
    1.055 * @math.pow(value, 1.0 / 2.4) - 0.055
  }
  (clamp_unit(encoded) * 255.0 + 0.5).to_int()
}

///|
fn mix_channel(
  a : Int32,
  b : Int32,
  amount : Double,
  space : MixSpace,
) -> Int32 {
  match space {
    Srgb =>
      (a.to_double() * (1.0 - amount) + b.to_double() * amount + 0.5).to_int()
    LinearRgb =>
      encode_channel(
        linear_channel(a) * (1.0 - amount) + linear_channel(b) * amount,
      )
  }
}

///|
/// Amount zero returns a, one returns b. Reject NaN and infinity.
pub fn mix(
  a : Rgb,
  b : Rgb,
  amount : Double,
  space : MixSpace,
) -> Result[Rgb, ColorError] {
  if !valid_amount(amount) {
    return Err(InvalidAmount)
  }
  let (ar, ag, ab) = a.channels()
  let (br, bg, bb) = b.channels()
  rgb(
    mix_channel(ar, br, amount, space),
    mix_channel(ag, bg, amount, space),
    mix_channel(ab, bb, amount, space),
  )
}

///|
/// Includes both endpoints; singleton is the start color. Bound allocations.
pub fn gradient(
  a : Rgb,
  b : Rgb,
  count : Int32,
  space : MixSpace,
) -> Result[Array[Rgb], ColorError] {
  if count < 1 || count > 4096 {
    return Err(InvalidCount)
  }
  let colors = [a]
  for i = 1; i < count; i = i + 1 {
    colors.push(
      mix(a, b, i.to_double() / (count - 1).to_double(), space).unwrap(),
    )
  }
  Ok(colors)
}

///|
pub fn Rgb::tint(self : Rgb, amount : Double) -> Result[Rgb, ColorError] {
  mix(self, rgb(255, 255, 255).unwrap(), amount, Srgb)
}

///|
pub fn Rgb::shade(self : Rgb, amount : Double) -> Result[Rgb, ColorError] {
  mix(self, rgb(0, 0, 0).unwrap(), amount, Srgb)
}

///|
/// Rotate HSL hue by any finite number of degrees.
pub fn Rgb::rotate_hue(self : Rgb, degrees : Double) -> Result[Rgb, ColorError] {
  let rotation = degrees % 360.0
  if !(rotation >= -360.0 && rotation <= 360.0) {
    return Err(InvalidAmount)
  }
  let (h, s, l) = self.to_hsl().components()
  let mut hue = (h + rotation) % 360.0
  if hue < 0.0 {
    hue = hue + 360.0
  }
  Ok(hsl(hue, s, l).unwrap().to_rgb())
}

///|
pub fn Rgb::complement(self : Rgb) -> Rgb {
  self.rotate_hue(180.0).unwrap()
}

///|
pub fn Rgb::triadic(self : Rgb) -> Array[Rgb] {
  [self, self.rotate_hue(120.0).unwrap(), self.rotate_hue(240.0).unwrap()]
}

///|
pub fn Rgb::analogous(
  self : Rgb,
  angle : Double,
) -> Result[Array[Rgb], ColorError] {
  if !(angle >= 0.0 && angle <= 180.0) {
    return Err(InvalidAmount)
  }
  Ok([self.rotate_hue(-angle).unwrap(), self, self.rotate_hue(angle).unwrap()])
}

///|
/// Saturation adjustment in percentage points; clamp the resulting value.
pub fn Rgb::adjust_saturation(
  self : Rgb,
  delta : Double,
) -> Result[Rgb, ColorError] {
  if !(delta >= -100.0 && delta <= 100.0) {
    return Err(InvalidAmount)
  }
  let (h, s, l) = self.to_hsl().components()
  Ok(hsl(h, clamp_unit((s + delta) / 100.0) * 100.0, l).unwrap().to_rgb())
}

///|
pub fn Rgb::adjust_lightness(
  self : Rgb,
  delta : Double,
) -> Result[Rgb, ColorError] {
  if !(delta >= -100.0 && delta <= 100.0) {
    return Err(InvalidAmount)
  }
  let (h, s, l) = self.to_hsl().components()
  Ok(hsl(h, s, clamp_unit((l + delta) / 100.0) * 100.0).unwrap().to_rgb())
}

///|
/// Select the candidate with maximum contrast. Ties keep the first candidate.
pub fn best_foreground(background : Rgb, candidates : Array[Rgb]) -> Rgb? {
  let mut best = None
  let mut best_ratio = 0.0
  for color in candidates {
    let ratio = contrast_ratio(color, background)
    if ratio > best_ratio {
      best = Some(color)
      best_ratio = ratio
    }
  }
  best
}

///|
pub fn readable_foregrounds(
  background : Rgb,
  candidates : Array[Rgb],
  level : Level,
  size : TextSize,
) -> Array[Rgb] {
  let result = []
  for color in candidates {
    if passes_contrast(color, background, level, size) {
      result.push(color)
    }
  }
  result
}

///|
/// One row for each unordered pair; indices refer to the input palette.
#derive(Eq, Debug)
pub struct ContrastPair {
  first : Int32
  second : Int32
  ratio : Double
  passes : Bool
}

///|
/// Limit quadratic work to at most 256 palette entries.
pub fn audit_palette(
  colors : Array[Rgb],
  level : Level,
  size : TextSize,
) -> Result[Array[ContrastPair], ColorError] {
  if colors.length() > 256 {
    return Err(InvalidCount)
  }
  let rows = []
  for i = 0; i < colors.length(); i = i + 1 {
    for j = i + 1; j < colors.length(); j = j + 1 {
      let ratio = contrast_ratio(colors[i], colors[j])
      rows.push({
        first: i,
        second: j,
        ratio,
        passes: ratio >= required_contrast(level, size),
      })
    }
  }
  Ok(rows)
}
