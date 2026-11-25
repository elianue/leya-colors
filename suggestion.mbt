///|
/// A suggestion is always accompanied by its measured result.
#derive(Eq, Debug)
pub struct ContrastSuggestion {
  color : Rgb
  ratio : Double
  required : Double
  passes : Bool
  changed : Bool
}

///|
/// Preserve the original when it passes; report failure explicitly when the
/// black/white search cannot reach the requested threshold on this background.
pub fn suggest_contrast(
  original : Rgb,
  background : Rgb,
  level : Level,
  size : TextSize,
) -> ContrastSuggestion {
  let color = suggest_foreground(original, background, level, size)
  let ratio = contrast_ratio(color, background)
  let required = required_contrast(level, size)
  {
    color,
    ratio,
    required,
    passes: ratio >= required,
    changed: color != original,
  }
}
