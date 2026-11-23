///|
test "exact text thresholds include equality but reject an epsilon below" {
  for level in [AA, AAA] {
    for size in [Normal, Large] {
      let threshold = required_contrast(level, size)
      assert_false(ratio_passes(threshold - 0.000000001, level, size))
      assert_true(ratio_passes(threshold, level, size))
      assert_true(ratio_passes(threshold + 0.000000001, level, size))
    }
  }
}
