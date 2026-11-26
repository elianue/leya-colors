///|
fn sample_candidate(name : String, hex : String) -> @colors.TokenCandidate {
  { name, color: @colors.from_hex(hex).unwrap(), }
}

///|
fn sample_surface(
  name : String,
  hex : String,
  level : @colors.Level,
  size : @colors.TextSize,
) -> @colors.TokenSurface {
  { name, background: @colors.from_hex(hex).unwrap(), level, size, }
}

///|
test "shared token rejects a gray that passes white but fails the second surface" {
  let result = @colors.select_shared_text_token(
    [
      sample_candidate("original", "#777777"),
      sample_candidate("white-only fix", "#767676"),
      sample_candidate("approved plum", "#6B5163"),
    ],
    [
      sample_surface("default", "#FFFFFF", @colors.AA, @colors.Normal),
      sample_surface("selected", "#FDE7EF", @colors.AA, @colors.Normal),
    ],
  )
  guard result.status is @colors.Selected(2) else { fail("expected plum") }
  let white_only = result.candidates[1]
  assert_true(white_only.checks[0].passes)
  assert_false(white_only.checks[1].passes)
  assert_eq(white_only.checks[1].surface, "selected")
  assert_eq(result.candidates[2].candidate.color.to_hex(), "#6B5163")
  assert_true(result.candidates[2].passes)
}

///|
test "shared token chooses the first match, preserves evidence and per-use size" {
  let result = @colors.select_shared_text_token(
    [
      sample_candidate("preferred", "#767676"),
      sample_candidate("fallback", "#000000"),
    ],
    [
      sample_surface("caption", "#FFFFFF", @colors.AA, @colors.Normal),
      sample_surface("large title", "#FDE7EF", @colors.AA, @colors.Large),
    ],
  )
  guard result.status is @colors.Selected(0) else {
    fail("expected first match")
  }
  assert_eq(result.candidates.length(), 2)
  assert_eq(result.candidates[0].checks[0].required, 4.5)
  assert_eq(result.candidates[0].checks[1].required, 3.0)
  assert_true(result.candidates[1].passes)
}

///|
test "shared token blocks when only black and white are approved but neither passes all uses" {
  let result = @colors.select_shared_text_token(
    [sample_candidate("light", "#FFFFFF"), sample_candidate("dark", "#000000")],
    [
      sample_surface("light card", "#FFFFFF", @colors.AA, @colors.Normal),
      sample_surface("dark card", "#111111", @colors.AA, @colors.Normal),
    ],
  )
  assert_true(result.status is @colors.NoApprovedMatch)
  assert_false(result.candidates[0].checks[0].passes)
  assert_true(result.candidates[0].checks[1].passes)
  assert_true(result.candidates[1].checks[0].passes)
  assert_false(result.candidates[1].checks[1].passes)
}

///|
test "shared token never passes an empty set of backgrounds or candidates" {
  let no_surfaces = @colors.select_shared_text_token(
    [sample_candidate("black", "#000000")],
    [],
  )
  let no_candidates = @colors.select_shared_text_token([], [
    sample_surface("white", "#FFFFFF", @colors.AA, @colors.Normal),
  ])
  assert_true(no_surfaces.status is @colors.MissingSurfaces)
  assert_true(no_candidates.status is @colors.MissingCandidates)
  assert_true(no_surfaces.candidates.is_empty())
  assert_true(no_candidates.candidates.is_empty())
}
