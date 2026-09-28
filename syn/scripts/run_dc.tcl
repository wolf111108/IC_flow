# ============================================================
# Design Compiler synthesis script
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

set USE_DW           [get_env_or USE_DW "0"]
set DW_ROOT          [get_env_or DW_ROOT ""]
set DW_SYN_LIB_DIR   [get_env_or DW_SYN_LIB_DIR ""]
set DW_SYNTHETIC_LIB [get_env_or DW_SYNTHETIC_LIB "dw_foundation.sldb"]

set PROJECT_ROOT [get_env_or PROJECT_ROOT [file normalize "../.."]]
set TOP_DESIGN   [get_env_or TOP_DESIGN "bit_serial_mac_unsigned"]
set TARGET_LIB   [get_env_or DC_TARGET_LIB ""]
set RTL_LIST     [get_env_or RTL_LIST "$PROJECT_ROOT/dv/filelists/rtl.f"]
set SDC_FILE     [get_env_or SDC_FILE "$PROJECT_ROOT/constraints/top.sdc"]

set RTL_LIST [make_abs $RTL_LIST $PROJECT_ROOT]
set SDC_FILE [make_abs $SDC_FILE $PROJECT_ROOT]

set WORK_DIR    "$PROJECT_ROOT/syn/work"
set REPORT_DIR  "$PROJECT_ROOT/syn/reports"
set NETLIST_DIR "$PROJECT_ROOT/syn/netlist"

file mkdir $WORK_DIR
file mkdir $REPORT_DIR
file mkdir $NETLIST_DIR
file mkdir "$WORK_DIR/dc_work"
file mkdir "$WORK_DIR/alib"

set_app_var alib_library_analysis_path "$WORK_DIR/alib"
set_svf "$WORK_DIR/${TOP_DESIGN}.svf"

# ------------------------------------------------------------
# Library setup
# ------------------------------------------------------------
set_app_var target_library [list $TARGET_LIB]

if {$USE_DW eq "1"} {
    puts "DesignWare support enabled"
    puts "DW_ROOT          = $DW_ROOT"
    puts "DW_SYN_LIB_DIR   = $DW_SYN_LIB_DIR"
    puts "DW_SYNTHETIC_LIB = $DW_SYNTHETIC_LIB"

    if {![file isdirectory $DW_ROOT]} {
        error "DW_ROOT not found: $DW_ROOT"
    }

    if {![file isdirectory $DW_SYN_LIB_DIR]} {
        error "DW_SYN_LIB_DIR not found: $DW_SYN_LIB_DIR"
    }

    set dw_sldb [file join $DW_SYN_LIB_DIR $DW_SYNTHETIC_LIB]

    if {![file exists $dw_sldb]} {
        error "DesignWare synthetic library not found: $dw_sldb"
    }

    # Set DesignWare root (Tcl variable, not app_var)
    # Works across all DC versions: set is core Tcl
    # Do NOT use set_app_var — hdlin_dwroot is not a registered app var
    set hdlin_dwroot $DW_ROOT
    set_app_var synthetic_library [list $DW_SYNTHETIC_LIB]

    set_app_var search_path [
        list \
            $PROJECT_ROOT \
            $DW_SYN_LIB_DIR
    ]

    set_app_var link_library [
        list \
            "*" \
            $TARGET_LIB \
            $DW_SYNTHETIC_LIB
    ]
} else {
    puts "DesignWare support disabled"

    set_app_var search_path [list $PROJECT_ROOT]
    set_app_var link_library [list "*" $TARGET_LIB]
}

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

    lappend rtl_files [make_abs $line $PROJECT_ROOT]
}
close $fp

if {[llength $rtl_files] == 0} {
    error "RTL filelist is empty: $RTL_LIST"
}

puts "============================================================"
puts "PROJECT_ROOT = $PROJECT_ROOT"
puts "TOP_DESIGN   = $TOP_DESIGN"
puts "TARGET_LIB   = $TARGET_LIB"
puts "RTL_LIST     = $RTL_LIST"
puts "SDC_FILE     = $SDC_FILE"
puts "RTL files:"
foreach f $rtl_files {
    puts "  $f"
}
puts "============================================================"

# ------------------------------------------------------------
# Analyze / elaborate
# ------------------------------------------------------------
remove_design -all
define_design_lib WORK -path "$WORK_DIR/dc_work"

analyze -library WORK -format verilog $rtl_files
elaborate $TOP_DESIGN -library WORK
link
current_design $TOP_DESIGN

# report DesignWare / resource usage
report_resources > "$REPORT_DIR/designware_pre_compile.rpt"

check_design > "$REPORT_DIR/check_design_pre_compile.rpt"

# ------------------------------------------------------------
# Constraints
# ------------------------------------------------------------
source $SDC_FILE
check_timing > "$REPORT_DIR/check_timing_pre_compile.rpt"

# ------------------------------------------------------------
# Synthesis
# ------------------------------------------------------------
set verilogout_no_tri true
set_fix_multiple_port_nets -all -buffer_constants
uniquify
compile_ultra

# report DesignWare / resource usage
report_resources > "$REPORT_DIR/designware_post_compile.rpt"

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------
check_design > "$REPORT_DIR/check_design_post_compile.rpt"
check_timing > "$REPORT_DIR/check_timing_post_compile.rpt"

report_area > "$REPORT_DIR/area.rpt"
report_power > "$REPORT_DIR/power.rpt"
report_timing -max_paths 20 > "$REPORT_DIR/timing.rpt"

report_timing -nosplit -transition_time -capacitance -nets -max_paths 20 \
    > "$REPORT_DIR/timing_setup.rpt"

report_timing -nosplit -delay min -transition_time -capacitance -nets -max_paths 20 \
    > "$REPORT_DIR/timing_hold.rpt"

report_constraint -nosplit -all_violators \
    > "$REPORT_DIR/constraint.rpt"

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
write -format verilog -hierarchy \
    -output "$NETLIST_DIR/${TOP_DESIGN}_syn.v"

write_sdc "$NETLIST_DIR/${TOP_DESIGN}_syn.sdc"
write_sdf "$NETLIST_DIR/${TOP_DESIGN}_syn.sdf"

exit