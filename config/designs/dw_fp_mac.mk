# ============================================================
# DesignWare DW_fp_mac design profile
# ============================================================

TOP_DESIGN := dw_fp_mult_pipe
TB_TOP     := tb_dw_fp_mult_pipe

RTL_LIST  := $(PROJECT_ROOT)/dv/filelists/rtl_dw_fp_mac.f
TB_LIST   := $(PROJECT_ROOT)/dv/filelists/tb_dw_fp_mac.f
GATE_LIST := $(PROJECT_ROOT)/dv/filelists/gate_dw_fp_mac.f

TB_FILE := $(PROJECT_ROOT)/dv/tb/tb_dw_fp_mac_pipe.v
SDC_FILE := $(PROJECT_ROOT)/constraints/dw_fp_mac/top.sdc

USE_DW := 1