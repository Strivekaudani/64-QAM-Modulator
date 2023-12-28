set search_path [list . $search_path} "/apps/design_kits/ibm_kits/IBM_IP/ibm_cmos8hp/std_cell/sc/v.20110613/synopsys/ss_125" "../src" "../db"]
set target_library IBM_CMOS8HP_SS125.db
set link_library { * IBM_CMOS8HP_SS125.db }
set acs_work_dir "."

set DESIGN "modulator_64qam_top"

# analyze design
analyze -format verilog { ../../source/modulator_64qam_top.v }
analyze -format verilog { ../../source/baseband_data.v }
analyze -format verilog { ../../source/symbol_mapping.v }
analyze -format verilog { ../../source/reset_synchronization.v }
analyze -format verilog { ../../source/spi_interface.v }
analyze -format verilog { ../../source/symbol_storage.v }
analyze -format verilog { ../../source/sync_ff_sync_1b.v }
analyze -format verilog { ../../source/sync_fifo.v }
analyze -format verilog { ../../source/sync_fifo_10b.v }
analyze -format verilog { ../../source/sync_fifo_ff_sync_4b.v }
analyze -format verilog { ../../source/sync_fifo_read_counter.v }
analyze -format verilog { ../../source/sync_fifo_reg_array.v }
analyze -format verilog { ../../source/sync_fifo_reg_array_10b.v }
analyze -format verilog { ../../source/sync_fifo_write_counter.v }
analyze -format verilog { ../../source/control_fsm.v }

# elaborate design
elaborate ${DESIGN} -architecture verilog -library DEFAULT
uniquify

# constraints
source ../constraints/constraints_${DESIGN}.tcl

# check design for issues
check_design

# compile design
compile -exact_map

#compile -map_effort high -incremental

# reports
## worst case timing paths
redirect ../reports/${DESIGN}_timing_worst.rpt {report_timing -path full -delay max -nworst 20 -max_paths 20 -significant_digits 3 -sort_by group }

redirect ../reports/${DESIGN}_area.rpt {report_area}

redirect ../reports/${DESIGN}_area_hier.rpt {report_area -hierarchy }

# write netlist
write -hierarchy -format verilog -output ../netlists/${DESIGN}_syn.v
