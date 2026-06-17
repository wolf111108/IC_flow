# ============================================================
# SpyGlass Lint script
# ============================================================

set TOP_DESIGN $::env(TOP_DESIGN)
set RTL_LIST   $::env(RTL_LIST)

set WORK_DIR   "lint/work"
set REPORT_DIR "lint/reports"

file mkdir $WORK_DIR
file mkdir $REPORT_DIR

puts "============================================================"
puts "SpyGlass Lint"
puts "TOP_DESIGN = $TOP_DESIGN"
puts "RTL_LIST   = $RTL_LIST"
puts "============================================================"

# ------------------------------------------------------------
# Create project
# ------------------------------------------------------------

new_project $WORK_DIR/${TOP_DESIGN}_lint.prj -force

# ------------------------------------------------------------
# Basic options
# ------------------------------------------------------------

set_option top $TOP_DESIGN

# 如果 RTL 是纯 Verilog，用 verilog 即可
set_option language_mode verilog

# 如果后面你用 SystemVerilog，可以改成：
# set_option language_mode mixed

# ------------------------------------------------------------
# Read RTL filelist
# ------------------------------------------------------------

set rtl_files {}

set fp [open $RTL_LIST r]
while {[gets $fp line] >= 0} {
    set line [string trim $line]

    if {$line == ""} {
        continue
    }

    if {[string index $line 0] == "#"} {
        continue
    }

    lappend rtl_files $line
}
close $fp

puts "RTL files:"
foreach f $rtl_files {
    puts "  $f"
    read_file -type verilog $f
}

# ------------------------------------------------------------
# Run lint goal
# ------------------------------------------------------------

current_goal lint/lint_rtl
run_goal

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------

write_report summary > $REPORT_DIR/lint_summary.rpt

save_project

exit -force