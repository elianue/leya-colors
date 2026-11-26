#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
cp "$here"/examples/palette-forge/{moon.mod,moon.pkg,main.mbt} "$work"/
# Copy exactly the library module; it need not ship with upstream installed.
mkdir "$work/leya-colors"
cp "$here"/{moon.mod,moon.pkg,README.md} "$here"/*.mbt "$work/leya-colors/"
git init -q "$work/palette-forge"
git -C "$work/palette-forge" fetch -q --depth=1 https://github.com/lkdrt/moonbit-palette-forge.git 4ac93f263658d0dad50b673f2d09f6811bbf4486
git -C "$work/palette-forge" checkout -q --detach FETCH_HEAD
cat > "$work/moon.work" <<'WORKSPACE'
members = [
  ".",
  "leya-colors",
  "palette-forge",
]
WORKSPACE
(cd "$work" && moon run . --target wasm)
