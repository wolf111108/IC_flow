# ============================================================
# Top-level SDC
# ============================================================

if {[info script] ne ""} {
    set SDC_DIR [file dirname [file normalize [info script]]]
} elseif {[info exists ::env(PROJECT_ROOT)]} {
    set SDC_DIR [file normalize [file join $::env(PROJECT_ROOT) constraints]]
} else {
    set SDC_DIR [file normalize constraints]
}

puts "Loading SDC files from: $SDC_DIR"

foreach sdc_file {
    clock.sdc
    io.sdc
    reset.sdc
    exceptions.sdc
} {
    set full_sdc [file join $SDC_DIR $sdc_file]

    if {![file exists $full_sdc]} {
        error "Cannot find SDC file: $full_sdc"
    }

    puts "  source $full_sdc"
    source $full_sdc
}

unset SDC_DIR
unset full_sdc
unset sdc_file