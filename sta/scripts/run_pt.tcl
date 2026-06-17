# ============================================================
# PrimeTime STA script
# ============================================================

proc get_env_or {var default} {
    if {[info exists ::env($var)] && $::env($var) ne ""} {
        return $::env($var)
    } else {
        return $default
    }
}

proc make_abs {path root} {
    if {[file pathtype $path] eq "absolute"} {
        return $path
    } else {
        return [file normalize [file join $root $path]]
    }
}

set PROJECT_ROOT [get_env_or PROJECT_ROOT [file normalize "."]]
set TOP_DESIGN   [get_env_or TOP_DESIGN "bit_serial_mac_unsigned"]
set NETLIST      [get_env_or SYN_NETLIST "$PROJECT_ROOT/syn/netlist/${TOP_DESIGN}_syn.v"]
set SDC_FILE     [get_env_or SYN_SDC "$PROJECT_ROOT/syn/netlist/${TOP_DESIGN}_syn.sdc"]
set TARGET_LIB   [get_env_or PT_TARGET_LIB ""]

set REPORT_DIR "$PROJECT_ROOT/sta/reports"
set WORK_DIR   "$PROJECT_ROOT/sta/work"
set SDF_DIR    "$PROJECT_ROOT/sta/sdf"

file mkdir $REPORT_DIR
file mkdir $WORK_DIR
file mkdir $SDF_DIR

set NETLIST  [make_abs $NETLIST  $PROJECT_ROOT]
set SDC_FILE [make_abs $SDC_FILE $PROJECT_ROOT]

puts "============================================================"
puts "PrimeTime STA"
puts "TOP_DESIGN = $TOP_DESIGN"
puts "NETLIST    = $NETLIST"
puts "SDC_FILE   = $SDC_FILE"
puts "TARGET_LIB = $TARGET_LIB"
puts "============================================================"

# ------------------------------------------------------------
# Library setup
# ------------------------------------------------------------

set_app_var target_library [list $TARGET_LIB]
set_app_var link_library   [list "*" $TARGET_LIB]
set_app_var search_path    [list $PROJECT_ROOT]

# ------------------------------------------------------------
# Read design
# ------------------------------------------------------------

read_verilog $NETLIST
current_design $TOP_DESIGN
link_design

# ------------------------------------------------------------
# Read constraints
# Make SDC compatible with old PrimeTime.
# PT M-2016 supports SDC version up to 2.0.
# ------------------------------------------------------------

set PT_SDC_FILE "$WORK_DIR/${TOP_DESIGN}_pt_compat.sdc"

set in_fp  [open $SDC_FILE r]
set out_fp [open $PT_SDC_FILE w]

while {[gets $in_fp line] >= 0} {
    if {[regexp {^set[ \t]+sdc_version[ \t]+} $line]} {
        puts $out_fp "set sdc_version 2.0"
    } else {
        puts $out_fp $line
    }
}

close $in_fp
close $out_fp

puts "Using PT-compatible SDC: $PT_SDC_FILE"
read_sdc $PT_SDC_FILE

# ------------------------------------------------------------
# Timing analysis
# ------------------------------------------------------------

redirect -file "$REPORT_DIR/check_timing.rpt" {
    check_timing
}

update_timing

if {[llength [info commands report_global_timing]] > 0} {
    redirect -file "$REPORT_DIR/global_timing.rpt" {
        report_global_timing
    }
}

redirect -file "$REPORT_DIR/qor.rpt" {
    report_qor
}

redirect -file "$REPORT_DIR/clock.rpt" {
    report_clock
}

redirect -file "$REPORT_DIR/port.rpt" {
    report_port
}

redirect -file "$REPORT_DIR/timing_setup.rpt" {
    report_timing -delay_type max -max_paths 50 -nosplit
}

redirect -file "$REPORT_DIR/timing_hold.rpt" {
    report_timing -delay_type min -max_paths 50 -nosplit
}

redirect -file "$REPORT_DIR/constraint.rpt" {
    report_constraint -all_violators -nosplit
}

redirect -file "$REPORT_DIR/analysis_coverage.rpt" {
    report_analysis_coverage -nosplit
}

# Optional: write SDF from PrimeTime
write_sdf "$SDF_DIR/${TOP_DESIGN}_pt.sdf"

exit