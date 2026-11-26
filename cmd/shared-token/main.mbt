///|
fn main {
  // Example product spec: the same caption token ships in both card states.
  let surfaces : Array[@colors.TokenSurface] = [
    {
      name: "default",
      background: @colors.from_hex("#FFFFFF").unwrap(),
      level: @colors.AA,
      size: @colors.Normal,
    },
    {
      name: "selected",
      background: @colors.from_hex("#FDE7EF").unwrap(),
      level: @colors.AA,
      size: @colors.Normal,
    },
  ]
  let candidates : Array[@colors.TokenCandidate] = [
    { name: "original", color: @colors.from_hex("#777777").unwrap(), },
    { name: "single-surface fix", color: @colors.from_hex("#767676").unwrap(), },
    { name: "approved plum", color: @colors.from_hex("#6B5163").unwrap(), },
  ]
  let report = @colors.select_shared_text_token(candidates, surfaces)
  for candidate in report.candidates {
    println("\{candidate.candidate.name} \{candidate.candidate.color.to_hex()}")
    for check in candidate.checks {
      println(
        "  \{check.surface}: \{check.ratio}:1 (needs \{check.required}:1), passes=\{check.passes}",
      )
    }
  }
  match report.status {
    @colors.Selected(index) =>
      println(
        "Ship one shared caption token: \{report.candidates[index].candidate.color.to_hex()}",
      )
    _ => abort("Do not ship: review the approved palette or card backgrounds")
  }
}
