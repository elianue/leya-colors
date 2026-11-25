///|
/// HSV with hue in degrees and saturation/value in percent.
#derive(Eq, Debug)
pub struct Hsv {
  priv hue : Double
  priv saturation : Double
  priv value : Double
}

///|
pub fn hsv(h : Double, s : Double, v : Double) -> Result[Hsv, ColorError] {
  if !(h >= 0.0 &&
    h <= 360.0 &&
    s >= 0.0 &&
    s <= 100.0 &&
    v >= 0.0 &&
    v <= 100.0) {
    return Err(InvalidHsv)
  }
  Ok({ hue: if h == 360.0 { 0.0 } else { h }, saturation: s, value: v, })
}

///|
pub fn Hsv::components(self : Hsv) -> (Double, Double, Double) {
  (self.hue, self.saturation, self.value)
}

///|
pub fn Rgb::to_hsv(self : Rgb) -> Hsv {
  let (r, g, b) = self.channels()
  let hi = @cmp.maximum(r, @cmp.maximum(g, b))
  let lo = @cmp.minimum(r, @cmp.minimum(g, b))
  let delta = hi - lo
  if delta == 0 {
    return { hue: 0.0, saturation: 0.0, value: hi.to_double() / 255.0 * 100.0, }
  }
  let mut hue = if hi == r {
    (g - b).to_double() / delta.to_double()
  } else if hi == g {
    (b - r).to_double() / delta.to_double() + 2.0
  } else {
    (r - g).to_double() / delta.to_double() + 4.0
  }
  hue = hue * 60.0
  if hue < 0.0 {
    hue = hue + 360.0
  }
  {
    hue,
    saturation: delta.to_double() / hi.to_double() * 100.0,
    value: hi.to_double() / 255.0 * 100.0,
  }
}

///|
pub fn Hsv::to_rgb(self : Hsv) -> Rgb {
  let v = self.value / 100.0
  let c = v * self.saturation / 100.0
  let sector = self.hue / 60.0
  let x = c * (1.0 - (sector % 2.0 - 1.0).abs())
  let (r, g, b) = if sector < 1.0 {
    (c, x, 0.0)
  } else if sector < 2.0 {
    (x, c, 0.0)
  } else if sector < 3.0 {
    (0.0, c, x)
  } else if sector < 4.0 {
    (0.0, x, c)
  } else if sector < 5.0 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  let m = v - c
  rgb(
    ((r + m) * 255.0 + 0.5).to_int(),
    ((g + m) * 255.0 + 0.5).to_int(),
    ((b + m) * 255.0 + 0.5).to_int(),
  ).unwrap()
}

///|
pub fn Hsv::to_hex(self : Hsv) -> String {
  self.to_rgb().to_hex()
}

///|
pub fn Hsv::to_hsl(self : Hsv) -> Hsl {
  let v = self.value / 100.0
  let s = self.saturation / 100.0
  let l = v * (1.0 - s / 2.0)
  let denominator = @cmp.minimum(l, 1.0 - l)
  let saturation = if denominator <= 0.0 { 0.0 } else { (v - l) / denominator }
  hsl(self.hue, clamp_unit(saturation) * 100.0, clamp_unit(l) * 100.0).unwrap()
}

///|
pub fn Hsl::to_hsv(self : Hsl) -> Hsv {
  let (h, s, l) = self.components()
  let lightness = l / 100.0
  let v = lightness + s / 100.0 * @cmp.minimum(lightness, 1.0 - lightness)
  let saturation = if v == 0.0 { 0.0 } else { 2.0 * (1.0 - lightness / v) }
  hsv(h, clamp_unit(saturation) * 100.0, clamp_unit(v) * 100.0).unwrap()
}

///|
fn clamp_unit(value : Double) -> Double {
  @cmp.maximum(0.0, @cmp.minimum(1.0, value))
}
