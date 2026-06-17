# config/pdk/tsmc65lp.tcl

set PDK_ROOT "/NAS/pdk/tsmc/tsmc65_LP/PDK_V1808/original/201808/SC/tcbn65lp_200a/TSMCHOME"

set TARGET_LIB "$PDK_ROOT/digital/Back_End/milkyway/tcbn65lp_200a/cell_frame/tcbn65lp/LM/tcbn65lptc.db"

set STD_CELL_VERILOG "$PDK_ROOT/digital/Front_End/verilog/tcbn65lp_200a/tcbn65lp.v"

set_app_var target_library [list $TARGET_LIB]
set_app_var link_library   [list "*" $TARGET_LIB]