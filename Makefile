SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

# ============================================================
# Project setup
# ============================================================

PROJECT_ROOT := $(CURDIR)

include config/project.mk
include config/tools.mk

.DEFAULT_GOAL := help

# ============================================================
# Tool setup
# ============================================================

XRUN     ?= xrun
DC_SHELL ?= dc_shell

SPYGLASS_ROOT    ?= /NAS/cad/synopsys/spyglass/P-2019.06-SP2-10
SPYGLASS_HOME    := $(SPYGLASS_ROOT)/SPYGLASS_HOME
SPYGLASS_PRELOAD ?= /lib64/libfreetype.so.6

# ============================================================
# Common simulation options
# ============================================================

XRUN_COMMON_OPTS := -64bit -sv -access +rwc -timescale 1ns/1ps

RTL_DEFINES     ?= +define+DUMP_VCD
GLS_DEFINES     ?= +define+GATE_SIM
GLS_SDF_DEFINES ?= +define+GATE_SIM +define+SDF_SIM

# ============================================================
# Directory setup
# ============================================================

DV_DIR   := dv
LINT_DIR := lint
CDC_DIR  := cdc
RDC_DIR  := rdc
SYN_DIR  := syn
LEC_DIR := lec
STA_DIR := sta
GLS_DIR  := gls

DV_LOG_DIR  := $(DV_DIR)/logs
DV_WORK_DIR := $(DV_DIR)/work

LINT_LOG_DIR  := $(LINT_DIR)/logs
LINT_WORK_DIR := $(LINT_DIR)/work
LINT_RPT_DIR  := $(LINT_DIR)/reports

CDC_LOG_DIR  := $(CDC_DIR)/logs
CDC_WORK_DIR := $(CDC_DIR)/work
CDC_RPT_DIR  := $(CDC_DIR)/reports

RDC_LOG_DIR  := $(RDC_DIR)/logs
RDC_WORK_DIR := $(RDC_DIR)/work
RDC_RPT_DIR  := $(RDC_DIR)/reports

SYN_LOG_DIR     := $(SYN_DIR)/logs
SYN_WORK_DIR    := $(SYN_DIR)/work
SYN_RPT_DIR     := $(SYN_DIR)/reports
SYN_NETLIST_DIR := $(SYN_DIR)/netlist

LEC_LOG_DIR  := $(LEC_DIR)/logs
LEC_WORK_DIR := $(LEC_DIR)/work
LEC_RPT_DIR  := $(LEC_DIR)/reports

STA_LOG_DIR  := $(STA_DIR)/logs
STA_WORK_DIR := $(STA_DIR)/work
STA_RPT_DIR  := $(STA_DIR)/reports
STA_SDF_DIR  := $(STA_DIR)/sdf

GLS_LOG_DIR  := $(GLS_DIR)/logs
GLS_WORK_DIR := $(GLS_DIR)/work
GLS_WAVE_DIR := $(GLS_DIR)/waves

# ============================================================
# Log files
# ============================================================

RTL_LOG     := $(DV_LOG_DIR)/rtl_sim.log
LINT_LOG    := $(LINT_LOG_DIR)/lint_spyglass.log
CDC_LOG     := $(CDC_LOG_DIR)/cdc.log
RDC_LOG     := $(RDC_LOG_DIR)/rdc.log
SYN_LOG     := $(SYN_LOG_DIR)/syn.log
GLS_LOG     := $(GLS_LOG_DIR)/gls.log
GLS_SDF_LOG := $(GLS_LOG_DIR)/gls_sdf.log
LEC_LOG := $(LEC_LOG_DIR)/formality.log
STA_LOG := $(STA_LOG_DIR)/pt.log

# ============================================================
# Tcl scripts
# ============================================================

LINT_TCL := $(LINT_DIR)/scripts/run_spyglass_lint.tcl
CDC_TCL  := $(CDC_DIR)/scripts/run_spyglass_cdc.tcl
RDC_TCL  := $(RDC_DIR)/scripts/run_spyglass_rdc.tcl
SYN_TCL  := $(SYN_DIR)/scripts/run_dc.tcl
FM_TCL := $(LEC_DIR)/scripts/run_formality.tcl
PT_TCL := $(STA_DIR)/scripts/run_pt.tcl

# ============================================================
# Xcelium command templates
# Keep these as single-line variables to avoid Makefile "\" continuation errors.
# ============================================================

RTL_XRUN_CMD     := $(XRUN) $(XRUN_COMMON_OPTS) $(RTL_DEFINES) -xmlibdirname $(DV_WORK_DIR)/xcelium_rtl.d -f $(DV_DIR)/filelists/tb.f -top $(TB_TOP) -l $(RTL_LOG)
GLS_XRUN_CMD     := $(XRUN) $(XRUN_COMMON_OPTS) $(GLS_DEFINES) -xmlibdirname $(GLS_WORK_DIR)/xcelium_gls.d -f $(DV_DIR)/filelists/gate.f -top $(TB_TOP) -l $(GLS_LOG)
GLS_SDF_XRUN_CMD := $(XRUN) $(XRUN_COMMON_OPTS) $(GLS_SDF_DEFINES) +SDF_FILE=$(SYN_SDF) +SDF_LOG=$(PROJECT_ROOT)/$(GLS_LOG_DIR)/sdf_annotate.log -xmlibdirname $(GLS_WORK_DIR)/xcelium_sdf.d -f $(DV_DIR)/filelists/gate.f -top $(TB_TOP) -l $(GLS_SDF_LOG)
# ============================================================
# Regression setup
# ============================================================

TESTS ?= basic corner random
SEEDS ?= 1 2 3 4 5

REGRESS_DIR := $(DV_DIR)/regress
REGRESS_LOG_DIR := $(REGRESS_DIR)/logs
REGRESS_WAVE_DIR := $(REGRESS_DIR)/waves

.PHONY: regression check_regression clean_regression

# ============================================================
# Phony targets
# ============================================================

.PHONY: help print-% all fe check_fe
.PHONY: rtl rtl_sim check_rtl clean_rtl clean_sim
.PHONY: lint lint_sg check_lint clean_lint
.PHONY: cdc cdc_sg check_cdc clean_cdc
.PHONY: rdc rdc_sg check_rdc clean_rdc
.PHONY: syn syn_run check_syn clean_syn
.PHONY: gls gls_sim check_gls clean_gls
.PHONY: gls_sdf gls_sdf_sim check_gls_sdf
.PHONY: clean clean_all clean_tool_junk
.PHONY: check_pdk
.PHONY: gen_gate_f
.PHONY: lec lec_fm check_lec clean_lec
.PHONY: sta sta_pt check_sta clean_sta

# ============================================================
# Help
# ============================================================

help:
	@echo "Frontend reference flow"
	@echo ""
	@echo "Main targets:"
	@echo "  make rtl          Run RTL simulation"
	@echo "  make lint         Run SpyGlass lint"
	@echo "  make cdc          Run SpyGlass CDC"
	@echo "  make rdc          Run SpyGlass RDC"
	@echo "  make syn          Run Design Compiler synthesis"
	@echo "  make gls          Run zero-delay gate-level simulation"
	@echo "  make gls_sdf      Run SDF gate-level simulation"
	@echo ""
	@echo "Full flow:"
	@echo "  make fe           Run rtl + lint + cdc + rdc + syn + gls + gls_sdf"
	@echo "  make check_fe     Check all generated logs"
	@echo ""
	@echo "Clean:"
	@echo "  make clean        Clean generated files"
	@echo "  make clean_all    Clean generated files and root tool junk"
	@echo ""
	@echo "Debug:"
	@echo "  make print-TOP_DESIGN"
	@echo "  make print-RTL_LIST"
	@echo "  make print-DC_TARGET_LIB"

print-%:
	@printf "%s\n" "$($*)"

# ============================================================
# Common helper macros
# ============================================================

define RUN_SPYGLASS
@mkdir -p $(2)/reports $(2)/logs $(2)/work $(2)/work/tmp $(2)/work/WORK
@echo "Running SpyGlass $(1)..."
@bash -lc 'set -o pipefail; export SPYGLASS_HOME="$(SPYGLASS_HOME)"; export TOP_DESIGN="$(TOP_DESIGN)"; export RTL_LIST="$(RTL_LIST)"; export SPYGLASS_TMPDIR="$(PROJECT_ROOT)/$(2)/work/tmp"; export TMPDIR="$$SPYGLASS_TMPDIR"; rm -rf WORK; mkdir -p "$$SPYGLASS_TMPDIR" "$(PROJECT_ROOT)/$(2)/work/WORK"; ln -s "$(PROJECT_ROOT)/$(2)/work/WORK" WORK; trap "rm -f WORK" EXIT; unset LD_PRELOAD LD_LIBRARY_PATH SPYGLASS_LD_LIBRARY_PATH; export SPYGLASS_LD_PRELOAD="$(SPYGLASS_PRELOAD)"; "$(SPYGLASS_HOME)/bin/spyglass" -shell -tcl "$(3)" 2>&1 | tee "$(4)"'
endef

define CHECK_SPYGLASS_LOG
@echo "Checking SpyGlass $(1) result..."
@log="$(2)"; if [ ! -f "$$log" ]; then echo "Missing log file: $$log"; exit 1; fi; summary_line=$$(grep -i "Reported Messages" "$$log" | tail -1); if [ -z "$$summary_line" ]; then echo "No SpyGlass summary found in $$log"; exit 1; fi; echo "$$summary_line"; if echo "$$summary_line" | grep -E "[1-9][0-9]*[[:space:]]+Fatals|[1-9][0-9]*[[:space:]]+Errors|[1-9][0-9]*[[:space:]]+Warnings" >/dev/null; then echo "SpyGlass $(1) FAIL: has fatal/error/warning messages"; exit 1; else echo "SpyGlass $(1) PASS: 0 fatal, 0 error, 0 warning"; fi
endef

define CHECK_XRUN_PASS
@echo "Checking $(1) result..."
@log="$(2)"; if [ ! -f "$$log" ]; then echo "Missing log file: $$log"; exit 1; fi; if grep -E '(\*E,|xrun: \*E|xmelab: \*E|xmsim: \*E)' "$$log" >/dev/null; then echo "$(1) FAIL: Xcelium error found"; grep -E '(\*E,|xrun: \*E|xmelab: \*E|xmsim: \*E)' "$$log" | tail -20; exit 1; fi; if grep -q "PASS" "$$log"; then grep "PASS" "$$log" | tail -5; echo "$(1) PASS"; else echo "$(1) FAIL: PASS string not found"; exit 1; fi
endef

# ============================================================
# Full flow
# ============================================================

all: fe

fe: rtl lint cdc rdc syn lec sta gls gls_sdf
	@echo "Frontend flow finished."

check_fe: check_rtl check_lint check_cdc check_rdc check_syn check_lec check_sta check_gls check_gls_sdf
	@echo "Frontend flow check finished."

# ============================================================
# RTL simulation
# ============================================================

rtl: rtl_sim check_rtl

rtl_sim:
	@mkdir -p $(DV_LOG_DIR) $(DV_WORK_DIR)
	@rm -rf $(DV_WORK_DIR)/xcelium_rtl.d
	$(RTL_XRUN_CMD)

check_rtl:
	$(call CHECK_XRUN_PASS,RTL simulation,$(RTL_LOG))

clean_rtl:
	rm -rf $(DV_WORK_DIR)/xcelium_rtl.d $(DV_LOG_DIR)/* wave.vcd

clean_sim: clean_rtl clean_regression

# ============================================================
# RTL simulation regression
# ============================================================

regression:
	@mkdir -p $(REGRESS_LOG_DIR) $(REGRESS_WAVE_DIR) $(DV_WORK_DIR)
	@echo "Running RTL regression..."
	@echo "TESTS = $(TESTS)"
	@echo "SEEDS = $(SEEDS)"
	@fail=0; total=0; pass=0; \
	for test in $(TESTS); do \
		for seed in $(SEEDS); do \
			total=$$((total+1)); \
			log="$(REGRESS_LOG_DIR)/rtl_$${test}_seed$${seed}.log"; \
			wave="$(REGRESS_WAVE_DIR)/rtl_$${test}_seed$${seed}.vcd"; \
			echo "============================================================"; \
			echo "TEST=$${test}, SEED=$${seed}"; \
			echo "LOG =$${log}"; \
			echo "WAVE=$${wave}"; \
			echo "============================================================"; \
			rm -rf "$(DV_WORK_DIR)/xcelium_regress_$${test}_$${seed}.d"; \
			$(XRUN) $(XRUN_COMMON_OPTS) $(RTL_DEFINES) \
				+TEST_NAME=$${test} \
				+SEED=$${seed} \
				+DUMPFILE=$${wave} \
				-xmlibdirname $(DV_WORK_DIR)/xcelium_regress_$${test}_$${seed}.d \
				-f $(DV_DIR)/filelists/tb.f \
				-top $(TB_TOP) \
				-l $${log}; \
			if grep -E "^FAIL$$|^FAIL:|\*E,|xrun: \*E|xmelab: \*E|xmsim: \*E" $${log} >/dev/null; then \
				echo "[FAIL] test=$${test}, seed=$${seed}"; \
				fail=$$((fail+1)); \
			elif grep -q "^PASS$$" $${log}; then \
				echo "[PASS] test=$${test}, seed=$${seed}"; \
				pass=$$((pass+1)); \
			else \
				echo "[FAIL] test=$${test}, seed=$${seed}: final PASS not found"; \
				fail=$$((fail+1)); \
			fi; \
		done; \
	done; \
	echo "============================================================"; \
	echo "Regression summary: total=$$total pass=$$pass fail=$$fail"; \
	if [ $$fail -ne 0 ]; then exit 1; fi

check_regression:
	@echo "Checking RTL regression result..."
	@expected=$$(( $(words $(TESTS)) * $(words $(SEEDS)) )); \
	logs=$$(find "$(REGRESS_LOG_DIR)" -maxdepth 1 -name "rtl_*.log" 2>/dev/null | wc -l); \
	pass=$$(grep -R -l "^PASS$$" "$(REGRESS_LOG_DIR)"/*.log 2>/dev/null | wc -l); \
	ok_cnt=$$(grep -R "^OK:" "$(REGRESS_LOG_DIR)"/*.log 2>/dev/null | wc -l); \
	echo "Expected runs = $$expected"; \
	echo "Log files     = $$logs"; \
	echo "PASS logs     = $$pass"; \
	echo "OK cases      = $$ok_cnt"; \
	if [ "$$logs" -ne "$$expected" ]; then \
		echo "Regression FAIL: log count mismatch"; \
		exit 1; \
	fi; \
	if grep -R -n -E "^FAIL$$|^FAIL:|\*E,|xrun: \*E|xmelab: \*E|xmsim: \*E" "$(REGRESS_LOG_DIR)"/*.log >/tmp/regress_fail.$$$$ 2>/dev/null; then \
		echo "Regression FAIL: failing pattern found"; \
		cat /tmp/regress_fail.$$$$; \
		rm -f /tmp/regress_fail.$$$$; \
		exit 1; \
	fi; \
	rm -f /tmp/regress_fail.$$$$; \
	if [ "$$pass" -ne "$$expected" ]; then \
		echo "Regression FAIL: not all logs have final PASS"; \
		exit 1; \
	fi; \
	echo "Regression PASS"

clean_regression:
	rm -rf $(REGRESS_DIR)
	rm -rf $(DV_WORK_DIR)/xcelium_regress_*.d
	rm -f wave.vcd

# ============================================================
# SpyGlass lint
# ============================================================

lint: lint_sg check_lint

lint_sg:
	$(call RUN_SPYGLASS,Lint,$(LINT_DIR),$(LINT_TCL),$(LINT_LOG))

check_lint:
	$(call CHECK_SPYGLASS_LOG,Lint,$(LINT_LOG))

clean_lint:
	rm -rf $(LINT_LOG_DIR)/* $(LINT_RPT_DIR)/* $(LINT_WORK_DIR)/* WORK

# ============================================================
# SpyGlass CDC
# ============================================================

cdc: cdc_sg check_cdc

cdc_sg:
	$(call RUN_SPYGLASS,CDC,$(CDC_DIR),$(CDC_TCL),$(CDC_LOG))

check_cdc:
	$(call CHECK_SPYGLASS_LOG,CDC,$(CDC_LOG))

clean_cdc:
	rm -rf $(CDC_LOG_DIR)/* $(CDC_RPT_DIR)/* $(CDC_WORK_DIR)/* WORK

# ============================================================
# SpyGlass RDC
# ============================================================

rdc: rdc_sg check_rdc

rdc_sg:
	$(call RUN_SPYGLASS,RDC,$(RDC_DIR),$(RDC_TCL),$(RDC_LOG))

check_rdc:
	$(call CHECK_SPYGLASS_LOG,RDC,$(RDC_LOG))

clean_rdc:
	rm -rf $(RDC_LOG_DIR)/* $(RDC_RPT_DIR)/* $(RDC_WORK_DIR)/* WORK

# ============================================================
# Design Compiler synthesis
# ============================================================

syn: check_pdk syn_run check_syn

syn_run:
	@mkdir -p $(SYN_WORK_DIR) $(SYN_LOG_DIR) $(SYN_RPT_DIR) $(SYN_NETLIST_DIR)
	@echo "Running Design Compiler synthesis..."
	@cd $(SYN_WORK_DIR) && PROJECT_ROOT="$(PROJECT_ROOT)" TOP_DESIGN="$(TOP_DESIGN)" \
	   RTL_LIST="$(RTL_LIST)" DC_TARGET_LIB="$(DC_TARGET_LIB)" \
	   SDC_FILE="$(PROJECT_ROOT)/constraints/top.sdc" \
	   $(DC_SHELL) -64bit -f $(PROJECT_ROOT)/$(SYN_TCL) 2>&1 | tee ../logs/syn.log

check_syn:
	@echo "Checking synthesis result..."
	@if [ ! -s "$(SYN_NETLIST)" ]; then echo "Synthesis FAIL: missing netlist $(SYN_NETLIST)"; exit 1; fi
	@if [ ! -s "$(SYN_SDC)" ]; then echo "Synthesis FAIL: missing SDC $(SYN_SDC)"; exit 1; fi
	@if [ ! -s "$(SYN_SDF)" ]; then echo "Synthesis FAIL: missing SDF $(SYN_SDF)"; exit 1; fi
	@if grep -i "^Error:" $(SYN_LOG) >/dev/null; then echo "Synthesis FAIL: DC error found"; grep -i "^Error:" $(SYN_LOG) | tail -20; exit 1; fi
	@echo "Synthesis PASS"

clean_syn:
	rm -rf $(SYN_WORK_DIR)/* $(SYN_LOG_DIR)/* $(SYN_RPT_DIR)/* $(SYN_NETLIST_DIR)/*
	rm -rf alib-52 command.log default.svf default.svg

# ============================================================
# Formality LEC
# ============================================================

lec: lec_fm check_lec

lec_fm:
	@mkdir -p $(LEC_LOG_DIR) $(LEC_RPT_DIR) $(LEC_WORK_DIR)
	@echo "Running Formality LEC..."
	@cd $(LEC_WORK_DIR) && \
	PROJECT_ROOT="$(PROJECT_ROOT)" \
	TOP_DESIGN="$(TOP_DESIGN)" \
	RTL_LIST="$(RTL_LIST)" \
	SYN_NETLIST="$(SYN_NETLIST)" \
	FORMAL_TARGET_LIB="$(FORMAL_TARGET_LIB)" \
	SVF_FILE="$(PROJECT_ROOT)/syn/work/$(TOP_DESIGN).svf" \
	$(FM_SHELL) -f ../../$(FM_TCL) \
	2>&1 | tee ../../$(LEC_LOG)

check_lec:
	@echo "Checking Formality LEC result..."
	@if [ ! -f "$(LEC_LOG)" ]; then \
		echo "Missing log file: $(LEC_LOG)"; \
		exit 1; \
	fi
	@if grep -i "Verification SUCCEEDED" "$(LEC_LOG)" >/dev/null; then \
		echo "Formality LEC PASS"; \
	else \
		echo "Formality LEC may have failed. Check $(LEC_LOG)"; \
		grep -i "Verification\|Fail\|Error" "$(LEC_LOG)" | tail -30 || true; \
		exit 1; \
	fi

clean_lec:
	rm -rf $(LEC_LOG_DIR)/* $(LEC_RPT_DIR)/* $(LEC_WORK_DIR)/*

# ============================================================
# PrimeTime STA
# ============================================================

sta: sta_pt check_sta

sta_pt:
	@mkdir -p $(STA_LOG_DIR) $(STA_RPT_DIR) $(STA_WORK_DIR) $(STA_SDF_DIR)
	@echo "Running PrimeTime STA..."
	@cd $(STA_WORK_DIR) && \
	PROJECT_ROOT="$(PROJECT_ROOT)" \
	TOP_DESIGN="$(TOP_DESIGN)" \
	SYN_NETLIST="$(SYN_NETLIST)" \
	SYN_SDC="$(SYN_SDC)" \
	PT_TARGET_LIB="$(PT_TARGET_LIB)" \
	LD_LIBRARY_PATH="$$HOME/lib_compat:$$LD_LIBRARY_PATH" \
	$(PT_SHELL) -f ../../$(PT_TCL) \
	2>&1 | tee ../../$(STA_LOG)

check_sta:
	@echo "Checking PrimeTime STA result..."
	@if [ ! -f "$(STA_LOG)" ]; then \
		echo "Missing log file: $(STA_LOG)"; \
		exit 1; \
	fi
	@if grep -i "^Error:" "$(STA_LOG)" >/dev/null; then \
		echo "PrimeTime STA FAIL: error found"; \
		grep -i "^Error:" "$(STA_LOG)" | tail -20; \
		exit 1; \
	fi
	@for rpt in \
		"$(STA_RPT_DIR)/check_timing.rpt" \
		"$(STA_RPT_DIR)/constraint.rpt" \
		"$(STA_RPT_DIR)/timing_setup.rpt" \
		"$(STA_RPT_DIR)/timing_hold.rpt" \
		"$(STA_RPT_DIR)/qor.rpt"; do \
		if [ ! -s "$$rpt" ]; then \
			echo "PrimeTime STA FAIL: missing report $$rpt"; \
			exit 1; \
		fi; \
	done
	@if grep -E "VIOLATED|violated" "$(STA_RPT_DIR)/constraint.rpt" >/dev/null; then \
		echo "PrimeTime STA FAIL: timing constraint violation found"; \
		grep -E "VIOLATED|violated" "$(STA_RPT_DIR)/constraint.rpt" | head -20; \
		exit 1; \
	fi
	@echo "PrimeTime STA PASS"

clean_sta:
	rm -rf $(STA_LOG_DIR)/* $(STA_RPT_DIR)/* $(STA_WORK_DIR)/* $(STA_SDF_DIR)/*

# ============================================================
# Zero-delay gate-level simulation
# ============================================================

gls: check_pdk gen_gate_f gls_sim check_gls

gls_sim:
	@mkdir -p $(GLS_LOG_DIR) $(GLS_WORK_DIR)
	@rm -rf $(GLS_WORK_DIR)/xcelium_gls.d
	$(GLS_XRUN_CMD)

check_gls:
	$(call CHECK_XRUN_PASS,GLS,$(GLS_LOG))

# ============================================================
# SDF gate-level simulation
# ============================================================

GLS_SDF_CMD_FILE := $(GLS_WORK_DIR)/sdf_cmd_file.cmd
SDF_ANNOTATE_LOG := $(PROJECT_ROOT)/$(GLS_LOG_DIR)/sdf_annotate.log

gls_sdf: check_pdk gen_gate_f gls_sdf_sim check_gls_sdf

gls_sdf_sim:
	@mkdir -p $(GLS_LOG_DIR) $(GLS_WORK_DIR)
	@rm -rf $(GLS_WORK_DIR)/xcelium_sdf.d
	@echo 'SDF_FILE = "$(SYN_SDF)",' > $(GLS_SDF_CMD_FILE)
	@echo 'SCOPE = $(TB_TOP).dut,' >> $(GLS_SDF_CMD_FILE)
	@echo 'MTM_CONTROL = "MAXIMUM",' >> $(GLS_SDF_CMD_FILE)
	@echo 'LOG_FILE = "$(SDF_ANNOTATE_LOG)";' >> $(GLS_SDF_CMD_FILE)
	$(XRUN) $(XRUN_COMMON_OPTS) \
		$(GLS_SDF_DEFINES) \
		-sdf_cmd_file $(GLS_SDF_CMD_FILE) \
		-sdf_verbose \
		-xmlibdirname $(GLS_WORK_DIR)/xcelium_sdf.d \
		-f $(DV_DIR)/filelists/gate.f \
		-top $(TB_TOP) \
		-l $(GLS_SDF_LOG)

check_gls_sdf:
	$(call CHECK_XRUN_PASS,SDF GLS,$(GLS_SDF_LOG))
	@echo "Checking SDF annotation log..."
	@if grep -Ei "CUSSTI|SDF System Task will be Ignored" "$(GLS_SDF_LOG)" >/dev/null; then \
		echo "SDF GLS FAIL: SDF system task was ignored by simulator"; \
		grep -Ei "CUSSTI|SDF System Task will be Ignored" "$(GLS_SDF_LOG)"; \
		exit 1; \
	fi
	@if ! grep -q "Reading SDF file" "$(GLS_SDF_LOG)"; then \
		echo "SDF GLS FAIL: SDF file was not read"; \
		exit 1; \
	fi
	@if ! grep -q "Annotating SDF timing data" "$(GLS_SDF_LOG)"; then \
		echo "SDF GLS FAIL: SDF timing data was not annotated"; \
		exit 1; \
	fi
	@if [ ! -s "$(GLS_LOG_DIR)/sdf_annotate.log" ]; then \
		echo "SDF GLS FAIL: sdf_annotate.log not found"; \
		exit 1; \
	fi
	@if grep -Ei "error|failed|cannot|not found" "$(GLS_LOG_DIR)/sdf_annotate.log" >/dev/null; then \
		echo "SDF GLS FAIL: SDF annotation error found"; \
		grep -Ei "error|failed|cannot|not found" "$(GLS_LOG_DIR)/sdf_annotate.log" | tail -30; \
		exit 1; \
	fi
	@grep -n -A20 "SDF statistics" "$(GLS_SDF_LOG)" || true
	@echo "SDF annotation check PASS"

clean_gls:
	rm -rf $(GLS_LOG_DIR)/* $(GLS_WORK_DIR)/* $(GLS_WAVE_DIR)/*

# ============================================================
# PDK check
# ============================================================

check_pdk:
	@echo "Checking PDK/library configuration..."
	@echo "PDK_NAME         = $(PDK_NAME)"
	@echo "PDK_ROOT         = $(PDK_ROOT)"
	@echo "DC_TARGET_LIB    = $(DC_TARGET_LIB)"
	@echo "STD_CELL_VERILOG = $(STD_CELL_VERILOG)"
	@test -d "$(PDK_ROOT)" || { echo "[ERROR] PDK_ROOT not found: $(PDK_ROOT)"; exit 1; }
	@test -f "$(DC_TARGET_LIB)" || { echo "[ERROR] DC_TARGET_LIB not found: $(DC_TARGET_LIB)"; exit 1; }
	@test -f "$(STD_CELL_VERILOG)" || { echo "[ERROR] STD_CELL_VERILOG not found: $(STD_CELL_VERILOG)"; exit 1; }
	@echo "PDK/library check PASS"

# ============================================================
# Gate filelist generation
# ============================================================

gen_gate_f:
	@echo "Generating $(GATE_LIST)"
	@mkdir -p $(dir $(GATE_LIST))
	@echo "-v $(STD_CELL_VERILOG)" > $(GATE_LIST)
	@echo "$(SYN_NETLIST)" >> $(GATE_LIST)
	@echo "$(PROJECT_ROOT)/dv/tb/$(TB_TOP).v" >> $(GATE_LIST)

# ============================================================
# Clean
# ============================================================

clean:
	$(MAKE) clean_rtl
	$(MAKE) clean_lint
	$(MAKE) clean_cdc
	$(MAKE) clean_rdc
	$(MAKE) clean_syn
	$(MAKE) clean_lec
	$(MAKE) clean_sta
	$(MAKE) clean_gls
	$(MAKE) clean_tool_junk

clean_all: clean

clean_tool_junk:
	rm -rf WORK xcelium.d alib-52 command.log default.svf default.svg
	rm -rf xrun.* *.key *.log *.X
