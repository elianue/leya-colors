///|
/// A solid background on which the same text token appears.
pub(all) struct TokenSurface {
  name : String
  background : Rgb
  level : Level
  size : TextSize
}

///|
/// A color approved by the design team. Input order is preference order.
pub(all) struct TokenCandidate {
  name : String
  color : Rgb
}

///|
/// The unrounded contrast measurement for one usage of a text token.
pub(all) struct TokenSurfaceCheck {
  surface : String
  ratio : Double
  required : Double
  passes : Bool
}

///|
/// Measurements for one approved candidate across all supplied surfaces.
pub(all) struct TokenCandidateCheck {
  candidate : TokenCandidate
  checks : Array[TokenSurfaceCheck]
  passes : Bool
}

///|
pub(all) enum SharedTokenStatus {
  MissingSurfaces
  MissingCandidates
  NoApprovedMatch
  Selected(Int32)
}

///|
/// A selection (index into candidates), or a blocker with per-surface evidence.
pub(all) struct SharedTokenResult {
  status : SharedTokenStatus
  candidates : Array[TokenCandidateCheck]
}

///|
/// Select the first approved foreground that passes every declared use.
/// Do not invent a shade, change the surfaces, or treat missing uses as a pass.
pub fn select_shared_text_token(
  candidates : Array[TokenCandidate],
  surfaces : Array[TokenSurface],
) -> SharedTokenResult {
  if surfaces.is_empty() {
    return { status: MissingSurfaces, candidates: [], }
  }
  if candidates.is_empty() {
    return { status: MissingCandidates, candidates: [], }
  }
  let audited = []
  let mut status = NoApprovedMatch
  for index, candidate in candidates {
    let checks = []
    let mut passes = true
    for surface in surfaces {
      let ratio = contrast_ratio(candidate.color, surface.background)
      let required = required_contrast(surface.level, surface.size)
      let pass = ratio >= required
      checks.push({ surface: surface.name, ratio, required, passes: pass, })
      passes = passes && pass
    }
    if passes {
      match status {
        NoApprovedMatch => status = Selected(index)
        _ => ()
      }
    }
    audited.push({ candidate, checks, passes, })
  }
  { status, candidates: audited, }
}
