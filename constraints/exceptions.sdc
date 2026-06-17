# exceptions.sdc
# 预留：多周期路径、虚假路径、case analysis 等
# 多周期路径示例：
# set_multicycle_path 2 -setup -from [get_pins reg_a/CK] -to [get_pins reg_b/D]
# set_multicycle_path 1 -hold  -from [get_pins reg_a/CK] -to [get_pins reg_b/D]
# 异步时钟组：
# set_clock_groups -asynchronous -group [get_clocks clk] -group [get_clocks clk_ext]