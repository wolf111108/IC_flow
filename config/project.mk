# ============================================================
# Design selection
# ============================================================

DESIGN ?= dw_fp_mac

DESIGN_CONFIG := $(PROJECT_ROOT)/config/designs/$(DESIGN).mk

ifeq ($(wildcard $(DESIGN_CONFIG)),)
$(error Design configuration not found: $(DESIGN_CONFIG))
endif

include $(DESIGN_CONFIG)

# ============================================================
# Common generated files
# ============================================================

SYN_NETLIST = $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.v
SYN_SDC     = $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.sdc
SYN_SDF     = $(PROJECT_ROOT)/syn/netlist/$(TOP_DESIGN)_syn.sdf