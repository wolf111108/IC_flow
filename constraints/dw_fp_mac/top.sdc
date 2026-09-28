# ============================================================
# DW_fp_mac registered wrapper constraints
# ============================================================

create_clock -name clk -period 9 [get_ports clk]

set_clock_uncertainty 0.2 [get_clocks clk]

set data_inputs [
    remove_from_collection \
        [all_inputs] \
        [get_ports {clk rst_n}]
]

if {[sizeof_collection $data_inputs] > 0} {
    set_input_delay 1.0 -clock clk $data_inputs
}

set_output_delay 1.0 -clock clk [all_outputs]

set_load 0.1 [all_outputs]

set_false_path -from [get_ports rst_n]