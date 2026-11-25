///|
/// Validated position and opaque color for a multi-stop gradient.
#derive(Eq, Debug)
pub struct ColorStop {
  priv position : Double
  priv color : Rgb
}

///|
pub fn color_stop(
  position : Double,
  color : Rgb,
) -> Result[ColorStop, ColorError] {
  if !valid_amount(position) {
    return Err(InvalidAmount)
  }
  Ok({ position, color, })
}

///|
pub fn ColorStop::components(self : ColorStop) -> (Double, Rgb) {
  (self.position, self.color)
}

///|
fn validate_stops(stops : Array[ColorStop]) -> Result[Unit, ColorError] {
  if stops.length() < 2 || stops.length() > 256 {
    return Err(InvalidCount)
  }
  if stops[0].position != 0.0 || stops[stops.length() - 1].position != 1.0 {
    return Err(InvalidAmount)
  }
  for i = 1; i < stops.length(); i = i + 1 {
    if stops[i].position <= stops[i - 1].position {
      return Err(InvalidAmount)
    }
  }
  Ok(())
}

///|
fn sample_valid_stops(
  stops : Array[ColorStop],
  position : Double,
  space : MixSpace,
) -> Rgb {
  if position == 0.0 {
    return stops[0].color
  }
  for i = 1; i < stops.length(); i = i + 1 {
    let right = stops[i]
    if position <= right.position {
      let left = stops[i - 1]
      let amount = (position - left.position) / (right.position - left.position)
      return mix(left.color, right.color, amount, space).unwrap()
    }
  }
  stops[stops.length() - 1].color
}

///|
/// Stops must be strictly ordered and cover exactly [0,1].
pub fn sample_stops(
  stops : Array[ColorStop],
  position : Double,
  space : MixSpace,
) -> Result[Rgb, ColorError] {
  if !valid_amount(position) {
    return Err(InvalidAmount)
  }
  match validate_stops(stops) {
    Err(e) => Err(e)
    Ok(_) => Ok(sample_valid_stops(stops, position, space))
  }
}

///|
/// Validate once, then sample uniformly; never allocate for invalid input.
pub fn gradient_stops(
  stops : Array[ColorStop],
  count : Int32,
  space : MixSpace,
) -> Result[Array[Rgb], ColorError] {
  if count < 1 || count > 4096 {
    return Err(InvalidCount)
  }
  match validate_stops(stops) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let colors = [stops[0].color]
  for i = 1; i < count; i = i + 1 {
    let position = i.to_double() / (count - 1).to_double()
    colors.push(sample_valid_stops(stops, position, space))
  }
  Ok(colors)
}

///|
/// Find the earliest step along an sRGB path to black or white that passes.
/// This is a discrete search with 256 steps, not a perceptual nearest color.
pub fn suggest_foreground(
  original : Rgb,
  background : Rgb,
  level : Level,
  size : TextSize,
) -> Rgb {
  if passes_contrast(original, background, level, size) {
    return original
  }
  let black = rgb(0, 0, 0).unwrap()
  let white = rgb(255, 255, 255).unwrap()
  for step = 1; step <= 255; step = step + 1 {
    let amount = step.to_double() / 255.0
    let dark = mix(original, black, amount, Srgb).unwrap()
    let light = mix(original, white, amount, Srgb).unwrap()
    let dark_passes = passes_contrast(dark, background, level, size)
    let light_passes = passes_contrast(light, background, level, size)
    if dark_passes && light_passes {
      return if contrast_ratio(dark, background) >=
        contrast_ratio(light, background) {
        dark
      } else {
        light
      }
    }
    if dark_passes {
      return dark
    }
    if light_passes {
      return light
    }
  }
  // AAA normal text can be impossible on a mid-luminance background.
  best_foreground(background, [black, white]).unwrap()
}
