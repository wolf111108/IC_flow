# 数字前端参考流程项目 README

## 1. 项目简介

本项目是一个可复用的数字 IC 前端参考流程项目，目前包含两个示例设计：无符号 bit-serial MAC `bit_serial_mac_unsigned`，以及基于 DesignWare 的浮点乘法流水线 `dw_fp_mult_pipe`（默认设计，可通过 `DESIGN` 变量切换，见下文“多设计支持”）。项目目标是把一个 RTL 设计从 coding 开始，串起 RTL 仿真、RTL regression、Lint、CDC、RDC、Design Compiler 综合、Formality 等价检查、PrimeTime STA、零延迟 GLS、SDF GLS 等步骤，形成一个可以迁移到其他数字前端项目的 flow 模板。

示例 DUT 功能为：输入操作数 `A` 以 bit-serial 方式逐位输入，权重 `W` 以 parallel 方式输入，最终输出：

```text
result = acc_init + A * W
```

当前默认参数为：

```text
A_WIDTH   = 8
W_WIDTH   = 8
ACC_WIDTH = 32
```

本项目重点不在于设计本身的复杂度，而在于把数字前端常见流程组织成一套清晰、可扩展、可检查、可复用的目录和 Makefile target。

### 多设计支持

项目支持通过 `DESIGN` 变量在多个设计之间切换，每个设计一个独立配置文件 `config/designs/<name>.mk`，当前包含：

```text
config/designs/bit_serial_mac.mk   # bit-serial MAC（无符号定点）
config/designs/dw_fp_mac.mk        # 基于 DesignWare DW_fp_mult 的流水线浮点乘法（默认）
```

切换设计：

```bash
make DESIGN=bit_serial_mac rtl     # 跑 bit-serial MAC 的 RTL 仿真
make DESIGN=dw_fp_mac fe           # 跑 dw_fp_mac 的完整前端 flow（默认）
```

默认设计由 `config/project.mk` 中的 `DESIGN ?= dw_fp_mac` 决定，若对应的 `config/designs/$(DESIGN).mk` 不存在，Makefile 会直接报错。

`dw_fp_mac` 设计简介：

```text
RTL     : rtl/top/dw_fp_mac_pipe.v（顶层 dw_fp_mult_pipe，内部例化 DesignWare DW_fp_mult）
TB      : dv/tb/tb_dw_fp_mac_pipe.v
filelist: dv/filelists/rtl_dw_fp_mac.f、dv/filelists/tb_dw_fp_mac.f
约束    : constraints/dw_fp_mac/top.sdc（clk period 9ns）
```

### DesignWare 支持

当设计 profile 中 `USE_DW := 1` 时：

```text
1. RTL 仿真：xrun 自动加 -y $(DW_SIM_DIR) +libext+.v+.sv+.inc +incdir+$(DW_SIM_DIR)，
   从 DesignWare 仿真模型目录解析 DW_fp_mult 等 DW 实例
2. DC 综合：run_dc.tcl 自动 link DW synthetic library（dw_foundation.sldb），
   使 DW 实例被正确综合
```

DW 相关路径集中在 `config/tools.mk`：

```makefile
DC_ROOT ?= /NAS/cad/synopsys/syn/Q-2019.12-SP5-5
DW_ROOT ?= $(DC_ROOT)/dw
DW_SIM_DIR ?= $(DW_ROOT)/sim_ver
DW_SYN_LIB_DIR ?= $(DC_ROOT)/libraries/syn
DW_SYNTHETIC_LIB ?= dw_foundation.sldb
```

---

## 2. 项目目录结构

```text
IC_flow/
├── Makefile                         # 顶层 flow 入口，定义 rtl/lint/cdc/rdc/syn/lec/sta/gls/gls_sdf 等 target
├── config/
│   ├── project.mk                    # 通用配置：DESIGN 选择、综合网表/SDC/SDF 通用路径
│   ├── tools.mk                      # 工具、module、PDK、标准单元库、DesignWare 配置
│   ├── designs/                      # 每个设计一个 profile：bit_serial_mac.mk、dw_fp_mac.mk
│   └── pdk/                          # 预留 PDK 配置脚本
├── rtl/
│   └── top/
│       ├── bit_serial_mac_unsigned.v # 示例 RTL DUT（bit-serial MAC）
│       └── dw_fp_mac_pipe.v          # DesignWare 浮点乘法流水线 DUT（默认设计）
├── dv/
│   ├── tb/
│   │   ├── tb_bit_serial_mac.v       # RTL/GLS 共用 testbench
│   │   └── tb_dw_fp_mac_pipe.v       # dw_fp_mac testbench
│   ├── filelists/
│   │   ├── rtl.f                     # RTL 文件列表（bit_serial_mac）
│   │   ├── tb.f                      # RTL 仿真文件列表（bit_serial_mac）
│   │   ├── rtl_dw_fp_mac.f           # RTL 文件列表（dw_fp_mac）
│   │   ├── tb_dw_fp_mac.f            # RTL 仿真文件列表（dw_fp_mac）
│   │   └── gate.f                    # GLS 文件列表，由 make gen_gate_f 自动生成
│   ├── logs/                         # RTL 单次仿真日志
│   ├── work/                         # Xcelium 编译工作目录
│   └── regress/                      # RTL regression 日志和波形
├── constraints/
│   ├── top.sdc                       # bit_serial_mac 顶层 SDC，统一 source 其他 SDC 文件
│   ├── dw_fp_mac/top.sdc             # dw_fp_mac 顶层 SDC
│   ├── clock.sdc                     # 时钟约束
│   ├── io.sdc                        # 输入/输出 delay 和 load
│   ├── reset.sdc                     # reset false path
│   └── exceptions.sdc                # 预留时序例外
├── lint/
│   └── scripts/run_spyglass_lint.tcl # SpyGlass lint 脚本
├── cdc/
│   ├── constraints/cdc.sgdc          # CDC 约束
│   └── scripts/run_spyglass_cdc.tcl  # SpyGlass CDC 脚本
├── rdc/
│   ├── constraints/rdc.sgdc          # RDC 约束
│   └── scripts/run_spyglass_rdc.tcl  # SpyGlass RDC 脚本
├── syn/
│   ├── scripts/run_dc.tcl            # Design Compiler 综合脚本
│   ├── netlist/                      # 综合输出网表/SDC/SDF
│   ├── reports/                      # 综合报告
│   └── work/                         # DC 工作目录，含 SVF
├── lec/
│   └── scripts/run_formality.tcl     # Formality 等价检查脚本
├── sta/
│   └── scripts/run_pt.tcl            # PrimeTime STA 脚本
├── gls/
│   ├── run_gate_sim.sh               # 预留 gate sim 脚本
│   ├── logs/                         # GLS/SDF GLS 日志
│   ├── work/                         # GLS 工作目录，含自动生成的 sdf_cmd_file.cmd
│   └── waves/                        # GLS 波形目录
└── scripts/
    └── env.csh                       # csh/tcsh 环境初始化脚本
```

---

## 3. 环境初始化

建议在项目根目录执行：

```csh
cd IC_flow
source scripts/env.csh
```

`env.csh` 会从 Makefile 中读取项目变量，并加载对应 EDA module。当前主要工具配置位于 `config/tools.mk`：

```makefile
XCELIUM_MODULE  := cadence/xcelium/2203_01
DC_MODULE       := synopsys/syn/Q-2019.12-SP5-5
SPYGLASS_MODULE := synopsys/spyglass/P-2019.06-SP2-10
VERDI_MODULE    := synopsys/verdi/P-2019.06-SP2-10
FORMALITY_MODULE ?= synopsys/formality/Q-2019.12-SP4
PT_MODULE ?= synopsys/pts/M-2016.12-SP2
```

当前标准单元库配置为 SMIC55 LL HD RVT：

```makefile
PDK_ROOT := /NAS/pdk/smic/smic55_LL/SC/SCC55NLL_HD_RVT_V2p1
DC_TARGET_LIB := $(PDK_ROOT)/liberty/0.9v/scc55nll_hd_rvt_ss_v0p81_125c_basic.db
STD_CELL_VERILOG := $(PDK_ROOT)/verilog/scc55nll_hd_rvt.v
PT_TARGET_LIB := $(DC_TARGET_LIB)
FORMAL_TARGET_LIB := $(DC_TARGET_LIB)
```

PrimeTime PTS M-2016.12-SP2 需要额外动态库路径。`make sta` 执行时，
Makefile 会自动把 `$HOME/compat_lib` 加到 `LD_LIBRARY_PATH` 最前面。
module load 则负责注入 PTS 自带的库路径。

如果机器上缺少 `libmng.so.1`，需要预先创建兼容目录，例如：

```csh
mkdir -p ~/compat_lib
ln -sf /usr/lib64/libmng.so.2.0.2 ~/compat_lib/libmng.so.1
```

---

## 4. 常用 Makefile 入口

### 4.1 查看帮助

```bash
make help
```

### 4.1.1 DesignWare 配置检查

```bash
make check_dw
```

检查 `USE_DW`、`DW_SIM_DIR`、`DW_SYNTHETIC_LIB` 等配置；当 `USE_DW=1` 时会验证 DW 仿真目录和 synthetic library 是否存在，不存在则报错退出。`make rtl` 和 `make syn` 已自动前置该检查。

### 4.2 单步 flow

```bash
make rtl          # RTL simulation
make regression   # RTL regression: 多 TEST、多 SEED
make lint         # SpyGlass lint
make cdc          # SpyGlass CDC
make rdc          # SpyGlass RDC
make syn          # Design Compiler synthesis
make lec          # Formality LEC
make sta          # PrimeTime STA
make gls          # zero-delay GLS
make gls_sdf      # SDF GLS
```

### 4.3 完整前端 flow

```bash
make fe
```

当前 `make fe` 依次执行：

```text
rtl -> lint -> cdc -> rdc -> syn -> lec -> sta -> gls -> gls_sdf
```

### 4.4 检查已有结果

```bash
make check_fe
```

### 4.5 清理

```bash
make clean
make clean_all
```

---

## 5. 完整流程说明

### 5.1 RTL 仿真

入口：

```bash
make rtl
```

使用文件：

```text
rtl/top/bit_serial_mac_unsigned.v
dv/tb/tb_bit_serial_mac.v
dv/filelists/tb.f
```

使用工具：

```text
Cadence Xcelium xrun
```

执行内容：

```text
1. 编译 testbench 和 RTL
2. elaboration
3. 运行 basic test
4. 检查 log 中是否存在 PASS，且无 Xcelium error
```

输出结果：

```text
dv/logs/rtl_sim.log
dv/work/xcelium_rtl.d/
wave.vcd 或通过 +DUMPFILE 指定的 VCD
```

当前 testbench 支持三类 test：

```text
basic   : 基本 directed case，例如 11*6、带 acc_init 的 case
corner  : 边界测试，例如 0、255*255、累加器溢出等
random  : 随机测试，默认每个 seed 运行 100 次
```

---

### 5.2 RTL Regression

入口：

```bash
make regression
make check_regression
```

默认配置：

```makefile
TESTS ?= basic corner random
SEEDS ?= 1 2 3 4 5
```

执行内容：

```text
对 TESTS × SEEDS 的组合逐个运行 RTL 仿真。
例如默认会运行 3 × 5 = 15 组仿真。
```

输出结果：

```text
dv/regress/logs/rtl_basic_seed1.log
dv/regress/logs/rtl_corner_seed1.log
dv/regress/logs/rtl_random_seed1.log
...
dv/regress/waves/*.vcd
```

检查规则：

```text
1. log 数量必须等于 TESTS × SEEDS
2. 每个 log 必须包含最终 PASS
3. 任意 log 中出现 FAIL 或 Xcelium error 均判定 regression FAIL
```

---

### 5.3 Lint

入口：

```bash
make lint
```

使用文件：

```text
dv/filelists/rtl.f
lint/scripts/run_spyglass_lint.tcl
rtl/top/bit_serial_mac_unsigned.v
```

使用工具：

```text
Synopsys SpyGlass
```

执行内容：

```text
1. 创建 SpyGlass project
2. 读取 RTL filelist
3. 设置 top design
4. 运行 lint/lint_rtl goal
5. 输出 summary report
```

输出结果：

```text
lint/logs/lint_spyglass.log
lint/reports/lint_summary.rpt
lint/work/
```

当前 Makefile 对 SpyGlass 做了运行环境处理：

```text
1. 设置 SPYGLASS_HOME
2. 创建独立 WORK 目录
3. 使用 SPYGLASS_LD_PRELOAD 规避 freetype 兼容问题
4. 不强制设置 SPYGLASS_LD_LIBRARY_PATH，避免 Tcl_VerifyChecksum 冲突
```

---

### 5.4 CDC 检查

入口：

```bash
make cdc
```

使用文件：

```text
dv/filelists/rtl.f
cdc/constraints/cdc.sgdc
cdc/scripts/run_spyglass_cdc.tcl
```

使用工具：

```text
Synopsys SpyGlass CDC
```

当前 CDC 约束：

```text
current_design bit_serial_mac_unsigned
clock -name clk -domain clk_domain
reset -name rst_n -value 0
```

执行内容：

```text
1. 读取 RTL
2. 读取 SGDC 约束
3. 运行 CDC goal
4. 输出 CDC summary report
```

输出结果：

```text
cdc/logs/cdc.log
cdc/reports/cdc_summary.rpt
cdc/work/
```

本设计只有一个 clock domain，因此 CDC 主要用于验证 flow 是否跑通。迁移到多时钟项目时，需要补充完整 clock domain、reset、synchronizer、async FIFO 等约束。

---

### 5.5 RDC 检查

入口：

```bash
make rdc
```

使用文件：

```text
dv/filelists/rtl.f
rdc/constraints/rdc.sgdc
rdc/scripts/run_spyglass_rdc.tcl
```

使用工具：

```text
Synopsys SpyGlass RDC
```

当前 RDC 约束：

```text
current_design bit_serial_mac_unsigned
clock -name clk -domain clk_domain
reset -name rst_n -value 0
```

当前使用 goal：

```text
rdc/rdc_verify_struct
```

输出结果：

```text
rdc/logs/rdc.log
rdc/reports/rdc_summary.rpt
rdc/work/
```

本设计只有一个异步低有效复位 `rst_n`，RDC 用于演示 reset domain checking flow。迁移到复杂项目时，需要补充 reset source、reset synchronizer、reset crossing waiver 等内容。

---

### 5.6 Design Compiler 综合

入口：

```bash
make syn
```

使用文件：

```text
rtl/top/bit_serial_mac_unsigned.v
dv/filelists/rtl.f
constraints/top.sdc
constraints/clock.sdc
constraints/io.sdc
constraints/reset.sdc
constraints/exceptions.sdc
syn/scripts/run_dc.tcl
config/tools.mk 中的 DC_TARGET_LIB
```

使用工具：

```text
Synopsys Design Compiler dc_shell
```

执行内容：

```text
1. 读取 RTL filelist
2. analyze / elaborate
3. link design
4. source SDC 约束
5. compile_ultra 综合
6. 生成面积、功耗、setup timing、hold timing、constraint report
7. 输出门级网表、综合网表 SDC、综合网表 SDF、SVF
```

主要输出：

```text
syn/netlist/bit_serial_mac_unsigned_syn.v
syn/netlist/bit_serial_mac_unsigned_syn.sdc
syn/netlist/bit_serial_mac_unsigned_syn.sdf
syn/work/bit_serial_mac_unsigned.svf
syn/reports/area.rpt
syn/reports/power.rpt
syn/reports/timing_setup.rpt
syn/reports/timing_hold.rpt
syn/reports/constraint.rpt
```

`SVF` 供 Formality 等价检查使用。

---

### 5.7 Formality LEC

入口：

```bash
make lec
```

使用文件：

```text
dv/filelists/rtl.f
syn/netlist/bit_serial_mac_unsigned_syn.v
syn/work/bit_serial_mac_unsigned.svf
lec/scripts/run_formality.tcl
config/tools.mk 中的 FORMAL_TARGET_LIB
```

使用工具：

```text
Synopsys Formality fm_shell
```

执行内容：

```text
1. read_db 标准单元库
2. set_svf 读取 DC 生成的 SVF
3. 读取 golden RTL
4. 读取 revised gate netlist
5. match
6. verify
7. 输出 matched/unmatched/failing/passing points report
```

主要输出：

```text
lec/logs/formality.log
lec/reports/matched_points.rpt
lec/reports/unmatched_points.rpt
lec/reports/failing_points.rpt
lec/reports/passing_points.rpt
```

通过标准：

```text
formality.log 中出现 Verification SUCCEEDED
```

---

### 5.8 PrimeTime STA

入口：

```bash
make sta
```

使用文件：

```text
syn/netlist/bit_serial_mac_unsigned_syn.v
syn/netlist/bit_serial_mac_unsigned_syn.sdc
sta/scripts/run_pt.tcl
config/tools.mk 中的 PT_TARGET_LIB
```

使用工具：

```text
Synopsys PrimeTime pt_shell
```

执行内容：

```text
1. 设置 target_library / link_library
2. read_verilog 读取综合网表
3. link_design
4. 读取综合后的 SDC
5. update_timing
6. 输出 check_timing、qor、clock、port、setup timing、hold timing、constraint、coverage report
7. 可选生成 PrimeTime SDF
```

主要输出：

```text
sta/logs/pt.log
sta/reports/check_timing.rpt
sta/reports/global_timing.rpt
sta/reports/qor.rpt
sta/reports/clock.rpt
sta/reports/port.rpt
sta/reports/timing_setup.rpt
sta/reports/timing_hold.rpt
sta/reports/constraint.rpt
sta/reports/analysis_coverage.rpt
sta/sdf/bit_serial_mac_unsigned_pt.sdf
```

当前项目已固化两个关键修复：

第一，针对旧 PrimeTime 只支持 SDC version 到 2.0 的问题，`run_pt.tcl` 会在 `sta/work` 下自动生成兼容副本：

```text
sta/work/bit_serial_mac_unsigned_pt_compat.sdc
```

其中会把：

```tcl
set sdc_version <newer_version>
```

替换为：

```tcl
set sdc_version 2.0
```

第二，报告输出使用 PrimeTime 更稳定的：

```tcl
redirect -file "xxx.rpt" { report_xxx }
```

而不是直接用 `>` 重定向，避免报告未生成但 flow 误判通过。

---

### 5.9 零延迟 GLS

入口：

```bash
make gls
```

使用文件：

```text
syn/netlist/bit_serial_mac_unsigned_syn.v
dv/tb/tb_bit_serial_mac.v
由 make gen_gate_f 生成的 dv/filelists/gate.f
标准单元 Verilog：STD_CELL_VERILOG
```

使用工具：

```text
Cadence Xcelium xrun
```

执行内容：

```text
1. 检查 PDK 和标准单元模型是否存在
2. 生成 gate.f
3. 编译标准单元 Verilog、门级网表和 testbench
4. 使用 +define+GATE_SIM 让 testbench 实例化非参数化 gate-level DUT
5. 运行门级功能仿真
```

输出结果：

```text
gls/logs/gls.log
gls/work/xcelium_gls.d/
```

---

### 5.10 SDF GLS

入口：

```bash
make gls_sdf
```

使用文件：

```text
syn/netlist/bit_serial_mac_unsigned_syn.v
syn/netlist/bit_serial_mac_unsigned_syn.sdf
dv/tb/tb_bit_serial_mac.v
dv/filelists/gate.f
gls/work/sdf_cmd_file.cmd
标准单元 Verilog：STD_CELL_VERILOG
```

使用工具：

```text
Cadence Xcelium xrun
```

执行内容：

```text
1. 生成 gate.f
2. 自动生成 gls/work/sdf_cmd_file.cmd
3. 使用 xrun -sdf_cmd_file 进行 SDF annotation
4. 使用 -sdf_verbose 输出详细 SDF statistics
5. 运行带延迟的门级仿真
6. 检查 SDF 是否真正被读取、标注，并检查 sdf_annotate.log 是否存在
```

当前 SDF command file 由 Makefile 自动生成，内容形式如下：

```text
SDF_FILE = ".../syn/netlist/bit_serial_mac_unsigned_syn.sdf",
SCOPE = tb_bit_serial_mac.dut,
MTM_CONTROL = "MAXIMUM",
LOG_FILE = ".../gls/logs/sdf_annotate.log";
```

主要输出：

```text
gls/logs/gls_sdf.log
gls/logs/sdf_annotate.log
gls/work/sdf_cmd_file.cmd
gls/work/xcelium_sdf.d/
```

检查规则：

```text
1. gls_sdf.log 中不能出现 Xcelium error
2. gls_sdf.log 中必须出现 PASS
3. gls_sdf.log 中不能出现 CUSSTI 或 This SDF System Task will be Ignored
4. gls_sdf.log 中必须出现 Reading SDF file
5. gls_sdf.log 中必须出现 Annotating SDF timing data
6. gls/logs/sdf_annotate.log 必须存在且非空
7. sdf_annotate.log 中不能出现 error / failed / cannot / not found 等严重关键字
```

---

## 6. 搭建过程中遇到的问题与解决方法

### 6.1 Makefile 命令格式问题

问题：

```text
Makefile: missing separator
```

原因：

```text
Makefile target 下的命令行必须以 TAB 开头，不能用空格。
```

解决：

```text
统一检查 help、check、clean 等 target 下的命令缩进，确保命令行以 TAB 开头。
```

---

### 6.2 Xcelium 命令续行导致参数丢失

问题：

```text
xrun command 被截断，出现 NOMOPT 或参数异常。
```

原因：

```text
Makefile 中多行命令续行不稳，部分反斜杠或变量展开导致 xrun 参数丢失。
```

解决：

```text
RTL_XRUN_CMD、GLS_XRUN_CMD 等改为单行命令变量，减少 Makefile 续行错误。
```

---

### 6.3 Testbench 和 DUT 的 posedge race

问题：

```text
RTL 仿真结果不匹配，例如期望 66，实际得到 132。
```

原因：

```text
testbench 在 posedge 附近驱动输入，和 DUT 在 posedge 采样输入形成 race。
```

解决：

```text
testbench 改为在 negedge clk 驱动 start、in_valid、a_bit、w、acc_init，保证 DUT 在下一个 posedge 采样时输入稳定。
```

---

### 6.4 SpyGlass freetype 兼容问题

问题：

```text
SpyGlass 启动时报 freetype 相关 undefined symbol。
```

解决：

```text
在 Makefile 中设置 SPYGLASS_LD_PRELOAD=/lib64/libfreetype.so.6。
```

同时避免强制设置 `LD_LIBRARY_PATH=/lib64:/usr/lib64`，否则可能触发 Tcl 库冲突。

---

### 6.5 CDC SGDC 语法问题

问题：

```text
SpyGlass 读取 SGDC 时报 Multiple values not allowed for field '-domain'。
```

原因：

```text
某些 SpyGlass SGDC 语法中不适合直接写 [get_ports clk] 一类 Tcl/Synopsys 风格对象表达式。
```

解决：

```text
使用 SpyGlass 兼容形式：
clock -name clk -domain clk_domain
reset -name rst_n -value 0
```

---

### 6.6 RDC goal 不兼容

问题：

```text
某些 SpyGlass 版本中原 RDC goal 不存在。
```

解决：

```text
RDC 使用 rdc/rdc_verify_struct。
```

---

### 6.7 DC 输出路径与 SVF 路径问题

问题：

```text
综合输出散落在错误目录，或者 Formality 找不到 SVF。
```

解决：

```text
run_dc.tcl 中统一使用 PROJECT_ROOT 构造绝对路径；
set_svf "$WORK_DIR/${TOP_DESIGN}.svf"；
所有 netlist/report/SDF/SDC 输出到 syn/ 对应目录下。
```

---

### 6.8 Formality fm_shell 找不到

问题：

```text
fm_shell: command not found
```

解决：

```text
在 config/tools.mk 中设置 FORMALITY_MODULE，并在 scripts/env.csh 中加载。
```

当前配置：

```makefile
FORMALITY_MODULE ?= synopsys/formality/Q-2019.12-SP4
```

---

### 6.9 PrimeTime 启动缺库

问题：

```text
pt_shell 启动时报 libmng.so.1 或 libnffr/libnffw/libnsys 找不到。
```

解决：

```text
使用 synopsys/pts/M-2016.12-SP2。
make sta 已在 Makefile 中自动设置：
LD_LIBRARY_PATH="$HOME/compat_lib:$LD_LIBRARY_PATH" pt_shell ...
module load 负责注入 PTS 自带的 linux64/pt/shlib 和 linux64/syn/bin。
用户只需预先创建 compat_lib 目录并放入缺失的 .so 软链接即可（见第 3 节）。
```

---

### 6.10 PrimeTime 不支持新版 SDC version

问题：

```text
Error: can't set "sdc_version": invalid value, must be one of: 1.0 ... 2.0
```

原因：

```text
DC Q-2019 生成的 SDC 版本可能高于 PT M-2016 支持的上限。
```

解决：

```text
sta/scripts/run_pt.tcl 中自动生成 PT-compatible SDC，把 sdc_version 改成 2.0 后再 read_sdc。
```

---

### 6.11 PrimeTime 报告没有生成

问题：

```text
STA log 显示执行 report 命令，但 sta/reports 下没有对应 rpt 文件。
```

原因：

```text
旧 PrimeTime 版本中直接使用 command > file 的方式不稳定。
```

解决：

```tcl
redirect -file "$REPORT_DIR/timing_setup.rpt" {
    report_timing -delay_type max -max_paths 50 -nosplit
}
```

同时 `check_sta` 会检查关键 report 是否存在且非空，避免假 PASS。

---

### 6.12 testbench 内部 `$sdf_annotate` 被 Xcelium 忽略

问题：

```text
xmelab: *W,CUSSTI: This SDF System Task will be Ignored.
```

原因：

```text
当前 Xcelium flow 中 testbench 内部使用 $sdf_annotate 的方式没有真正触发 SDF annotation。
```

解决：

```text
SDF GLS 改用 xrun -sdf_cmd_file gls/work/sdf_cmd_file.cmd -sdf_verbose。
```

修复后 log 中应出现：

```text
Reading SDF file ...
Annotating SDF timing data:
SDF statistics:
```

并生成：

```text
gls/logs/sdf_annotate.log
```

---

## 7. 当前已固化的关键改进

当前项目中已经固化了以下改进：

```text
1. 统一 PDK 和标准单元库配置到 config/tools.mk
2. SDC 拆分为 clock/io/reset/exceptions/top，top.sdc 使用鲁棒路径 source
3. RTL regression 支持多个 TEST、多个 SEED
4. testbench 支持 +TEST_NAME、+SEED、+DUMPFILE
5. Design Compiler 使用绝对路径输出 netlist/SDC/SDF/SVF/report
6. Formality LEC 已接入 make fe
7. PrimeTime STA 已接入 make fe
8. PrimeTime SDC version 2.0 兼容逻辑已固化
9. PrimeTime report 使用 redirect -file 方式生成
10. SDF GLS 已改为 xrun -sdf_cmd_file 方式
11. check_gls_sdf 已检查 SDF 是否真正读取和标注
12. env.csh 已加载 Formality、PrimeTime 等工具 module，并处理 PTS 动态库路径
```

---

## 8. 当前仍建议注意的问题

### 8.1 testbench 中仍保留 `$sdf_annotate` 代码

`dv/tb/tb_bit_serial_mac.v` 中仍存在 `ifdef SDF_SIM` 下的 `$sdf_annotate` 代码。不过当前 `make gls_sdf` 使用的是：

```text
+define+GATE_SIM
-sdf_cmd_file gls/work/sdf_cmd_file.cmd
```

没有再打开 `+define+SDF_SIM`，因此这段代码不会生效。

建议后续清理：

```text
1. 删除 testbench 中的 $sdf_annotate 代码；或
2. 保留但只打印说明，不再真正调用 $sdf_annotate。
```

这样可以避免未来其他人误用 `GLS_SDF_XRUN_CMD` 或重新打开 `SDF_SIM` 后再次触发 `CUSSTI`。

---

### 8.2 Makefile 中仍保留旧的 `GLS_SDF_XRUN_CMD`

Makefile 顶部仍定义：

```makefile
GLS_SDF_XRUN_CMD := ... +define+SDF_SIM +SDF_FILE=... +SDF_LOG=...
```

但实际 `gls_sdf_sim` 已经不用这个变量，而是直接调用：

```makefile
xrun ... +define+GATE_SIM -sdf_cmd_file ... -sdf_verbose ...
```

建议后续删除旧变量，避免误解。

---

### 8.3 交付 zip 中包含部分运行产物

当前 zip 中包含了一些运行产物，例如：

```text
dv/regress/logs/*.log
dv/regress/waves/*.vcd
dv/work/xcelium_regress_*.d/
bit_serial_mac_unsigned_syn.sdf.X
not
```

其中 `not` 是空文件，`bit_serial_mac_unsigned_syn.sdf.X` 是 Xcelium 编译后的 SDF 中间文件。

建议正式发布模板前执行：

```bash
make clean_all
rm -rf dv/regress
rm -f bit_serial_mac_unsigned_syn.sdf.X not
```

然后再压缩源码。这样项目更干净，也避免把本地运行产物误认为源文件。

---

### 8.4 `config/pdk/smic55.tcl` 目前为空

当前主要 PDK 配置已经集中在 `config/tools.mk`，因此 `config/pdk/smic55.tcl` 暂时没有实际作用。

建议未来二选一：

```text
1. 删除空文件，避免误解；或
2. 把不同 PDK 的 Tcl 配置真正接入 DC/PT/后端 flow。
```

---

### 8.5 CDC/RDC waiver 管理尚未系统化

当前项目可以跑通 CDC/RDC，但尚未形成正式 waiver 管理机制。

未来建议添加：

```text
lint/waivers/*.swl 或 *.awl
cdc/waivers/*.swl
rdc/waivers/*.swl
```

并在 SpyGlass Tcl 中统一 read waiver 文件。

---

### 8.6 多 corner STA 尚未完全启用

当前 STA 使用单个 slow corner：

```makefile
PT_TARGET_LIB := $(DC_TARGET_LIB)
```

虽然 `tools.mk` 中已经预留：

```makefile
PT_SETUP_LIB
PT_HOLD_LIB
TEMPUS_SETUP_LIB
TEMPUS_HOLD_LIB
```

但当前 `run_pt.tcl` 仍是单 corner 版本。

未来建议扩展为：

```text
setup corner: slow / max delay
hold corner : fast / min delay
```

或者引入 MCMM STA。

---

## 9. 复用到其他项目时需要修改的地方

### 9.1 添加新设计

现在推荐通过新增设计 profile 的方式接入新设计，而不是直接修改 `project.mk`。

文件：

```text
config/designs/<new_design>.mk
```

新增一个 profile，例如：

```makefile
TOP_DESIGN := your_top
TB_TOP     := your_tb_top

RTL_LIST  := $(PROJECT_ROOT)/dv/filelists/rtl_your_top.f
TB_LIST   := $(PROJECT_ROOT)/dv/filelists/tb_your_top.f
GATE_LIST := $(PROJECT_ROOT)/dv/filelists/gate_your_top.f

TB_FILE  := $(PROJECT_ROOT)/dv/tb/your_tb_top.v
SDC_FILE := $(PROJECT_ROOT)/constraints/your_top/top.sdc

USE_DW := 0   # 若使用 DesignWare 则设为 1
```

然后运行：

```bash
make DESIGN=your_top fe
```

通用输出路径由 `config/project.mk` 自动派生，无需逐个修改：

```makefile
SYN_NETLIST = $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.v
SYN_SDC     = $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.sdc
SYN_SDF     = $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.sdf
```

若要把新设计设为默认，修改 `project.mk` 中 `DESIGN ?= your_top` 即可。

---

### 9.2 修改 RTL 和 testbench filelist

文件：

```text
dv/filelists/rtl_<design>.f
dv/filelists/tb_<design>.f
```

例如：

```text
rtl/top/your_top.v
rtl/core/xxx.v
rtl/common/yyy.v
```

`tb_<design>.f` 应包含 testbench 和 RTL：

```text
dv/tb/your_tb_top.sv
rtl/top/your_top.v
...
```

---

### 9.3 修改 testbench

文件：

```text
dv/tb/tb_bit_serial_mac.v
```

需要替换为新项目 testbench，并保留类似机制：

```text
1. +TEST_NAME 支持不同 testcase
2. +SEED 支持随机 seed
3. +DUMPFILE 支持不同 regression 波形文件名
4. RTL/GLS 可共用 testbench
5. GATE_SIM 下实例化非参数化门级 DUT
```

如果新 DUT 有参数，RTL 模式可以参数化实例化；GLS 模式一般需要按综合网表顶层直接实例化。

---

### 9.4 修改约束

文件：

```text
constraints/clock.sdc
constraints/io.sdc
constraints/reset.sdc
constraints/exceptions.sdc
```

需要根据新设计修改：

```text
1. clock name、period、waveform
2. generated clock
3. input/output delay
4. load / driving cell
5. reset false path
6. multicycle path
7. false path
8. CDC/RDC 相关异步路径
```

`constraints/top.sdc` 可以保留作为统一入口。

---

### 9.5 修改 CDC/RDC 约束

文件：

```text
cdc/constraints/cdc.sgdc
rdc/constraints/rdc.sgdc
```

单时钟项目可以非常简单；多时钟项目需要明确：

```text
1. 所有 clock domain
2. reset domain
3. async reset
4. synchronizer
5. async FIFO
6. handshake crossing
7. waiver
```

---

### 9.6 修改 PDK 和标准单元库

文件：

```text
config/tools.mk
```

需要修改：

```makefile
PDK_NAME
PDK_ROOT
DC_TARGET_LIB
STD_CELL_VERILOG
FORMAL_TARGET_LIB
PT_TARGET_LIB
```

注意：

```text
1. DC / Formality / PrimeTime 使用 .db
2. GLS 使用标准单元 Verilog .v
3. .db 和 .v 必须来自同一个 PDK / 同一套标准单元库版本
4. 非 PG 网表使用普通 .v；PG 网表才使用带 VDD/VSS/VNW/VPW 的 PG model
```

---

### 9.7 修改工具 module

文件：

```text
config/tools.mk
scripts/env.csh
```

根据服务器环境修改：

```makefile
XCELIUM_MODULE
DC_MODULE
SPYGLASS_MODULE
VERDI_MODULE
FORMALITY_MODULE
PT_MODULE
TEMPUS_MODULE
```

如果工具命令名不同，也需要修改：

```makefile
XRUN
DC_SHELL
FM_SHELL
PT_SHELL
TEMPUS
```

---

### 9.8 修改 flow target

文件：

```text
Makefile
```

默认完整 flow 是：

```makefile
fe: rtl lint cdc rdc syn lec sta gls gls_sdf
```

如果某项目暂时不需要 GLS 或 LEC，可以改成：

```makefile
fe: rtl regression lint cdc rdc syn sta
```

如果要把 regression 纳入主流程，也可以改为：

```makefile
fe: regression lint cdc rdc syn lec sta gls gls_sdf
```

---

## 10. 后续发展方向

### 10.1 加入 waiver 管理

建议增加：

```text
lint/waivers/
cdc/waivers/
rdc/waivers/
```

并在 SpyGlass Tcl 中统一读取。这样可以区分真实问题和已确认可接受的问题。

---

### 10.2 加入 Verdi 波形入口

建议增加：

```bash
make verdi_rtl
make verdi_gls
make verdi_gls_sdf
```

功能：

```text
1. 自动加载对应 filelist
2. 自动打开 VCD/FSDB
3. 自动设置 top
```

---

### 10.3 增强 regression

当前 regression 已支持多 TEST、多 SEED。未来可以进一步加入：

```text
1. timeout 机制
2. parallel jobs，例如 make regression -j
3. summary.csv
4. failed case 自动重跑
5. GLS smoke regression
6. 覆盖率收集
```

---

### 10.4 增加 CI 检查

可以添加：

```text
1. make lint_fast
2. make rtl_smoke
3. make check_filelist
4. make check_no_abs_path
5. make package
```

用于提交前自动检查项目是否干净、路径是否可迁移。

---

### 10.5 多 corner / MCMM STA

当前 STA 是单 corner。未来可以扩展：

```text
1. setup slow corner
2. hold fast corner
3. multiple voltage / temperature corner
4. report 合并
5. constraint quality check
```

---

### 10.6 接入后端流程

当前项目主要到综合、LEC、STA、GLS。未来可以继续接入：

```text
1. floorplan
2. placement
3. CTS
4. routing
5. post-layout STA
6. post-layout SDF GLS
7. DRC / LVS
8. GDS export
```

---

## 11. 建议的最小使用流程

第一次使用：

```csh
cd IC_flow
source scripts/env.csh
make check_dw
make rtl
make regression
make lint
make cdc
make rdc
make syn
make lec
make sta
make gls
make gls_sdf
```

切换设计示例：

```bash
make DESIGN=bit_serial_mac fe   # 跑 bit-serial MAC 完整 flow
make fe                          # 默认跑 dw_fp_mac 完整 flow
```

常规完整流程：

```bash
make fe
```

检查已有结果：

```bash
make check_fe
```

打包前清理：

```bash
make clean_all
rm -rf dv/regress
rm -f bit_serial_mac_unsigned_syn.sdf.X not
```

---

## 12. 总结

本项目已经形成了一套较完整的数字前端参考 flow：

```text
RTL coding
  -> RTL simulation
  -> RTL regression
  -> Lint
  -> CDC
  -> RDC
  -> DC synthesis
  -> Formality LEC
  -> PrimeTime STA
  -> zero-delay GLS
  -> SDF GLS
```

它的主要价值是：

```text
1. 目录结构清晰
2. 工具入口统一
3. PDK 配置集中
4. SDC source 路径鲁棒
5. regression 支持多 testcase / seed
6. LEC / STA / GLS / SDF GLS 都有自动 check
7. 已处理实际服务器环境中的工具兼容问题
8. 适合作为后续数字前端项目的基础模板
```

对于新项目，重点修改 `config/project.mk`、`config/tools.mk`、`dv/filelists/*.f`、`constraints/*.sdc`、`cdc/rdc/*.sgdc` 和 testbench，即可复用大部分 flow。
