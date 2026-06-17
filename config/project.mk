# ============================================================
# Project configuration
# ============================================================

TOP_DESIGN := bit_serial_mac_unsigned
TB_TOP     := tb_bit_serial_mac

RTL_LIST  := $(PROJECT_ROOT)/dv/filelists/rtl.f
TB_LIST   := $(PROJECT_ROOT)/dv/filelists/tb.f
GATE_LIST := $(PROJECT_ROOT)/dv/filelists/gate.f

SYN_NETLIST := $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.v
SYN_SDC     := $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.sdc
SYN_SDF     := $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.sdf