# ============================================================
# Tool & Library configuration  (single source of truth)
# ------------------------------------------------------------
# 排布逻辑：
#   1) 本地覆盖      - 可选，给本机 / CI 覆盖用
#   2) EDA 工具       - module 名 + shell 可执行名
#   3) PDK / Corner  - 库根目录与各 corner 路径（只写一次）
#   4) 各工具绑定    - DC / STA / Formal 等引用上面的 corner 变量
# ============================================================


# ------------------------------------------------------------
# 1) 本地覆盖（可选）
# ------------------------------------------------------------
# 若 config/site.mk 存在则优先加载，可在其中覆盖任意变量，
# 例如换 PDK_ROOT / 改 module 版本，而无需修改本文件。
-include config/site.mk


# ============================================================
# 2) EDA tools
# ============================================================

# ---- module 名（供 scripts/env.csh module load 用）----------
XCELIUM_MODULE   ?= cadence/xcelium/2203_01
DC_MODULE        ?= synopsys/syn/Q-2019.12-SP5-5
SPYGLASS_MODULE  ?= synopsys/spyglass/P-2019.06-SP2-10
VERDI_MODULE     ?= synopsys/verdi/P-2019.06-SP2-10
FORMALITY_MODULE ?= synopsys/formality/Q-2019.12-SP4
PT_MODULE        ?= synopsys/pts/M-2016.12-SP2
CONFORMAL_MODULE ?= conformal/09.10.180
TEMPUS_MODULE    ?= ets/13.18.000

# ---- shell 入口（可直接命令行覆盖）-------------------------
DC_SHELL   ?= dc_shell
FM_SHELL   ?= fm_shell
CONFORMAL  ?= lec
PT_SHELL   ?= pt_shell
TEMPUS     ?= tempus
XRUN       ?= xrun


# ============================================================
# 3) PDK / standard-cell library
# ============================================================

# ---- 当前 PDK ----------------------------------------------
PDK_NAME ?= SMIC55_LL_HD_RVT
PDK_ROOT ?= /NAS/pdk/smic/smic55_LL/SC/SCC55NLL_HD_RVT_V2p1

# ---- Liberty 目录（按 voltage 分目录）----------------------
PDK_LIB_DIR ?= $(PDK_ROOT)/liberty/0.9v

# ---- 各 corner 的 .db（综合 / STA / Formality 用）----------
# slow / worst case (SS, 0.81V, 125C)
LIB_DB_SS ?= $(PDK_LIB_DIR)/scc55nll_hd_rvt_ss_v0p81_125c_basic.db
# fast / best case (FF, 0.99V, -40C)
LIB_DB_FF ?= $(PDK_LIB_DIR)/scc55nll_hd_rvt_ff_v0p99_-40c_basic.db

# ---- 各 corner 的 .lib（Tempus 等读文本库时用）-------------
LIB_LIB_SS ?= $(PDK_LIB_DIR)/scc55nll_hd_rvt_ss_v0p81_125c_basic.lib
LIB_LIB_FF ?= $(PDK_LIB_DIR)/scc55nll_hd_rvt_ff_v0p99_-40c_basic.lib

# ---- 标准单元 Verilog 模型（GLS 用）------------------------
STD_CELL_VERILOG ?= $(PDK_ROOT)/verilog/scc55nll_hd_rvt.v

# ---- 兼容旧名 STA_TIMING_LIB --------------------------------
STA_TIMING_LIB ?= $(LIB_LIB_SS)


# ============================================================
# 4) Per-tool library bindings
#   每个工具只挑需要的 corner；切换 corner 只要改这里的引用
# ============================================================

# ---- Design Compiler：单 corner 综合（slow）----------------
DC_TARGET_LIB ?= $(LIB_DB_FF)

# ---- PrimeTime：setup 用 SS / hold 用 FF -------------------
PT_TARGET_LIB ?= $(DC_TARGET_LIB)
PT_SETUP_LIB  ?= $(LIB_DB_SS)
PT_HOLD_LIB   ?= $(LIB_DB_FF)

# ---- Tempus：与 PT 对齐，但用 .lib -------------------------
TEMPUS_SETUP_LIB ?= $(LIB_LIB_SS)
TEMPUS_HOLD_LIB  ?= $(LIB_LIB_FF)

# ---- Formality：与 DC 一致 ---------------------------------
FORMAL_TARGET_LIB ?= $(DC_TARGET_LIB)

# ============================================================
# DesignWare configuration
# ============================================================

DC_ROOT ?= /NAS/cad/synopsys/syn/Q-2019.12-SP5-5

DW_ROOT          ?= $(DC_ROOT)/dw
DW_SIM_DIR       ?= $(DW_ROOT)/sim_ver
DW_SYN_LIB_DIR   ?= $(DC_ROOT)/libraries/syn
DW_SYNTHETIC_LIB ?= dw_foundation.sldb