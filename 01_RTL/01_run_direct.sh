vcs ../00_TB/tb.v CHIP.v -full64 -R -debug_access+all +define+$1 +v2k +notimingcheck
# vcs ../00_TB_public/tb.v CHIP.v -full64 -R -debug_access+all +define+$1 +v2k +notimingcheck
# xrun ../00_TB/tb.v CHIP_golden.v +define+$1 +access+r