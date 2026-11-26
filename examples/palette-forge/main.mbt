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
  // Same task, same approved colors, same preference, upstream measurements.
  // This baseline deliberately implements the policy without calling Leya's
  // selection or contrast calculation. Both engines must reach the same result.
  let mut forge_choice = -1
  for i, candidate in candidates {
    let fg = @forge_core.Color::from_hex(candidate.color.to_hex())
    let mut all_pass = true
    for j, surface in surfaces {
      let bg = @forge_core.Color::from_hex(surface.background.to_hex())
      let ratio = @forge.check_wcag(fg, bg).ratio
      let required = 4.5 // This reference handoff is AA normal text on both uses.
      let passes = ratio >= required
      let check = result.candidates[i].checks[j]
      if (ratio - check.ratio).abs() > 0.000000001 || passes != check.passes {
        abort("Upstream and Leya measurements disagree on the same handoff")
      }
      all_pass = all_pass && passes
      println(
        "Upstream policy baseline: \{candidate.name} / \{surface.name}: \{ratio}:1 passes=\{passes}",
      )
    }
    if all_pass && forge_choice == -1 {
      forge_choice = i
    }
  }
  guard result.status is @leya.Selected(index) else {
    abort("No single approved caption token satisfies both card states")
  }
  let chosen = result.candidates[index]
  if forge_choice != index ||
    index != 2 ||
    chosen.candidate.color.to_hex() != "#6B5163" {
    abort("Expected both selection policies to choose approved plum")
  }
  // Pin the published table to this upstream revision's final 8-bit output.
  if normal_fix.to_hex() != "#777777" || selected_fix.to_hex() != "#6b6b6b" {
    abort("Pinned upstream correction output differs from the comparison table")
  }
  println(
    "PASS: same-task upstream baseline and Leya select the same approved token",
  )
  println("Leya Colors shared token: \{chosen.candidate.color.to_hex()}")
  for check in chosen.checks {
    println("  \{check.surface}: \{check.ratio}:1 (needs \{check.required}:1)")
  }
}
