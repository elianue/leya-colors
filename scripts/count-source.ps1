$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
# Core library only: excludes tests, examples, CLI and build/vendor directories.
$total = 0
$strictTotal = 0
$rows = foreach ($file in Get-ChildItem -LiteralPath $root -Filter '*.mbt' | Sort-Object Name) {
    if ($file.Name -match '_(wb)?test\.mbt$') { continue }
    $lines = @(Get-Content -LiteralPath $file.FullName | Where-Object {
        $_.Trim().Length -gt 0 -and $_ -notmatch '^\s*//'
    })
    $strict = @($lines | Where-Object { $_ -notmatch '^\s*[{}()\[\],;]+\s*$' }).Count
    $total += $lines.Count
    $strictTotal += $strict
    [pscustomobject]@{ File = $file.Name; CodeLines = $lines.Count; WithoutDelimiterOnlyLines = $strict }
}
$rows | Format-Table -AutoSize
Write-Output "Core code lines (no blank/comment/test lines): $total"
Write-Output "Also excluding delimiter-only lines: $strictTotal"
if ($strictTotal -lt 500) { throw 'Core source is below the conservative 500-line target.' }
