# io.sdc
# 输入：相对 clk 的到达时间
set_input_delay  1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
# 输出：相对 clk 的要求时间
set_output_delay 1.0 -clock clk [all_outputs]

# 输入驱动模型（按真实 pad / 前级填写）
set_driving_cell -lib_cell BUFHDV4 -pin Z [all_inputs]
# 输出负载（pF）—— 默认 0.1，按实际外设调整
set_load 0.1 [all_outputs]
# 端口默认 transition（ns）
set_input_transition 0.2 [all_inputs]