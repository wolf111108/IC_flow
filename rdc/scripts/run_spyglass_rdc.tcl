# ============================================================
# SpyGlass RDC script
# ============================================================

set TOP_DESIGN $::env(TOP_DESIGN)
set RTL_LIST   $::env(RTL_LIST)

set WORK_DIR   "rdc/work"
set REPORT_DIR "rdc/reports"
set SGDC_FILE  "rdc/constraints/rdc.sgdc"

file mkdir $WORK_DIR
file mkdir $REPORT_DIR

puts "============================================================"
puts "SpyGlass RDC"
puts "TOP_DESIGN = $TOP_DESIGN"
puts "RTL_LIST   = $RTL_LIST"
puts "SGDC_FILE  = $SGDC_FILE"
puts "============================================================"

new_project $WORK_DIR/${TOP_DESIGN}_rdc.prj -force

current_methodology $::env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

set_option top $TOP_DESIGN
set_option language_mode verilog

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

if {[file exists $SGDC_FILE]} {
    read_file -type sgdc $SGDC_FILE
}

current_goal rdc/rdc_verify_struct
run_goal

write_report summary > $REPORT_DIR/rdc_summary.rpt

save_project
exit -force