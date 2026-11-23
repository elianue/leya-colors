///|
/// An opaque 8-bit sRGB color. Construct with `rgb` or `from_hex`.
#derive(Eq, Debug)
pub struct Rgb {
  priv red : Int32
  priv green : Int32
  priv blue : Int32
}

///|
/// HSL: hue in degrees [0,360), saturation and lightness in percent.
#derive(Eq, Debug)
pub struct Hsl {
  priv hue : Double
  priv saturation : Double
  priv lightness : Double
}

///|
/// Validation errors returned by constructors and parsers.
#derive(Eq, Debug)
pub(all) enum ColorError {
  InvalidRgb
  InvalidHsl
  InvalidHex
}

///|
/// Reject channels outside 0..255, without clamping.
pub fn rgb(r : Int32, g : Int32, b : Int32) -> Result[Rgb, ColorError] {
  if r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255 {
    Err(InvalidRgb)
  } else {
    Ok({ red: r, green: g, blue: b, })
  }
}

///|
/// Reject non-finite/out-of-range HSL values; normalize hue 360 to 0.
pub fn hsl(h : Double, s : Double, l : Double) -> Result[Hsl, ColorError] {
  if !(h >= 0.0 &&
    h <= 360.0 &&
    s >= 0.0 &&
    s <= 100.0 &&
    l >= 0.0 &&
    l <= 100.0) {
    Err(InvalidHsl)
  } else {
    Ok({ hue: if h == 360.0 { 0.0 } else { h }, saturation: s, lightness: l, })
  }
}

///|
pub fn Rgb::channels(self : Rgb) -> (Int32, Int32, Int32) {
  (self.red, self.green, self.blue)
}

///|
pub fn Hsl::components(self : Hsl) -> (Double, Double, Double) {
  (self.hue, self.saturation, self.lightness)
}

///|
fn hex_digit(c : UInt16) -> Int32? {
  if c >= 48 && c <= 57 {
    Some(c.to_int() - 48)
  } else if c >= 65 && c <= 70 {
    Some(c.to_int() - 55)
  } else if c >= 97 && c <= 102 {
    Some(c.to_int() - 87)
  } else {
    None
  }
}

///|
/// Parse exactly RGB or RRGGBB, optionally prefixed by '#'.
pub fn from_hex(text : String) -> Result[Rgb, ColorError] {
  let start = if text.length() > 0 && text[0] == 35 { 1 } else { 0 }
  let n = text.length() - start
  if n != 3 && n != 6 {
    return Err(InvalidHex)
  }
  let mut value = 0
  for i = start; i < text.length(); i = i + 1 {
    match hex_digit(text[i]) {
      None => return Err(InvalidHex)
      Some(d) => value = value * 16 + d
    }
  }
  if n == 3 {
    Ok({
      red: value / 256 * 17,
      green: value / 16 % 16 * 17,
      blue: value % 16 * 17,
    })
  } else {
    Ok({ red: value / 65536, green: value / 256 % 256, blue: value % 256, })
  }
}

///|
fn hex_byte(n : Int32) -> String {
  let digits = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
  ]
  digits[n / 16] + digits[n % 16]
}

///|
/// Canonical uppercase six-digit HEX with a leading '#'.
pub fn Rgb::to_hex(self : Rgb) -> String {
  "#" + hex_byte(self.red) + hex_byte(self.green) + hex_byte(self.blue)
}

///|
/// Convert sRGB to HSL; achromatic hue is zero.
pub fn Rgb::to_hsl(self : Rgb) -> Hsl {
  let r = self.red.to_double() / 255.0
  let g = self.green.to_double() / 255.0
  let b = self.blue.to_double() / 255.0
  let hi = @cmp.maximum(r, @cmp.maximum(g, b))
  let lo = @cmp.minimum(r, @cmp.minimum(g, b))
  let d = hi - lo
  let l = (hi + lo) / 2.0
  if d == 0.0 {
    return { hue: 0.0, saturation: 0.0, lightness: l * 100.0, }
  }
  let mut h = if hi == r {
    (g - b) / d
  } else if hi == g {
    (b - r) / d + 2.0
  } else {
    (r - g) / d + 4.0
  }
  h = h * 60.0
  if h < 0.0 {
    h = h + 360.0
  }
  {
    hue: h,
    saturation: d / (1.0 - (2.0 * l - 1.0).abs()) * 100.0,
    lightness: l * 100.0,
  }
}

///|
/// Convert HSL to 8-bit RGB, rounding to the nearest channel integer.
pub fn Hsl::to_rgb(self : Hsl) -> Rgb {
  let s = self.saturation / 100.0
  let l = self.lightness / 100.0
  let c = (1.0 - (2.0 * l - 1.0).abs()) * s
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
  let m = l - c / 2.0
  {
    red: ((r + m) * 255.0 + 0.5).to_int(),
    green: ((g + m) * 255.0 + 0.5).to_int(),
    blue: ((b + m) * 255.0 + 0.5).to_int(),
  }
}

///|
pub fn Hsl::to_hex(self : Hsl) -> String {
  self.to_rgb().to_hex()
}

///|
pub fn hex_to_hsl(text : String) -> Result[Hsl, ColorError] {
  match from_hex(text) {
    Ok(color) => Ok(color.to_hsl())
    Err(e) => Err(e)
  }
}
