///|
fn main {
  let current = @forge_core.Color::from_hex("#777777")
  let normal = @forge_core.Color::from_hex("#FFFFFF")
  let selected = @forge_core.Color::from_hex("#FDE7EF")
  // Compare the published, one-background remediation API on each card state.
  let normal_fix = @forge.fix_contrast(current, normal)
  let selected_fix = @forge.fix_contrast(current, selected)
  for
    (name, fixed) in [
      ("default fix", normal_fix),
      ("selected fix", selected_fix),
    ] {
    // Check the actual 8-bit color that the webpage would deploy, not the
    // internal floating-point value before HEX serialization.
    let hex = fixed.to_hex()
    let shipped = @forge_core.Color::from_hex(hex)
    println(
      "Palette Forge \{name}: \{hex}; default=\{@forge.check_wcag(shipped, normal).ratio}; selected=\{@forge.check_wcag(shipped, selected).ratio}",
    )
  }

  // Designer-approved order from the same product spec. Use Palette Forge HEX
  // output as the interchange format, not a shared implementation.
  let candidates : Array[@leya.TokenCandidate] = [
    {
      name: "current neutral",
      color: @leya.from_hex(current.to_hex()).unwrap(),
    },
    { name: "approved neutral", color: @leya.from_hex("#767676").unwrap(), },
    { name: "approved plum", color: @leya.from_hex("#6B5163").unwrap(), },
  ]
  let surfaces : Array[@leya.TokenSurface] = [
    {
      name: "default",
      background: @leya.from_hex(normal.to_hex()).unwrap(),
      level: @leya.AA,
      size: @leya.Normal,
    },
    {
      name: "selected",
      background: @leya.from_hex(selected.to_hex()).unwrap(),
      level: @leya.AA,
      size: @leya.Normal,
    },
  ]
  let result = @leya.select_shared_text_token(candidates, surfaces)
  guard result.status is @leya.Selected(index) else {
    abort("No single approved caption token satisfies both card states")
  }
  let chosen = result.candidates[index]
  println("Leya Colors shared token: \{chosen.candidate.color.to_hex()}")
  for check in chosen.checks {
    println("  \{check.surface}: \{check.ratio}:1 (needs \{check.required}:1)")
  }
}
