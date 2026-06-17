# reset.sdc
# 异步复位：复位释放不在 STA 路径内
set_false_path -from [get_ports rst_n]

# 复位 recovery / removal 检查（可选，需要 reset 时序库时启用）
# set_max_delay 2.0 -from [get_ports rst_n]
# set_min_delay 0.1 -from [get_ports rst_n]