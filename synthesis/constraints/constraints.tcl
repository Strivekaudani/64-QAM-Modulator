##################################
# Input/Output Constraints File
##################################

#####################
### SCLK
#####################

set CLK_PERIOD_SCLK 10000.00 
set CLK_LATENCY_SCLK 1.00
set CLK_SKEW_SCLK 0.50
set CLK_JITTER_SCLK 0.20
set SETUP_UNCERTAINTY_SCLK [expr $CLK_SKEW_SCLK + $CLK_JITTER_SCLK]
set INPUT_DELAY 1.00
set OUTPUT_DELAY 1.00

## Clock constraints
create_clock SCLK -period $CLK_PERIOD_SCLK -waveform {0.0 5000.0}
set_clock_latency $CLK_LATENCY_SCLK SCLK
set_clock_uncertainty -setup $SETUP_UNCERTAINTY_SCLK SCLK
set_clock_uncertainty -hold $CLK_SKEW_SCLK SCLK
set_clock_transition -rise 0.1 SCLK
set_clock_transition -fall 0.12 SCLK

#####################
### sym_clk
#####################

set CLK_PERIOD_SYM 100.00 
set CLK_LATENCY_SYM 1.00
set CLK_SKEW_SYM 0.50
set CLK_JITTER_SYM 0.20
set SETUP_UNCERTAINTY_SYM [expr $CLK_SKEW_SYM + $CLK_JITTER_SYM]
set INPUT_DELAY 1.00
set OUTPUT_DELAY 1.00

## Clock constraints
create_clock sym_clk -period $CLK_PERIOD_SYM -waveform {0.0 50.0}
set_clock_latency $CLK_LATENCY_SYM sym_clk
set_clock_uncertainty -setup $SETUP_UNCERTAINTY_SYM sym_clk
set_clock_uncertainty -hold $CLK_SKEW_SYM sym_clk
set_clock_transition -rise 0.1 sym_clk
set_clock_transition -fall 0.12 sym_clk

#####################
### data_clk
#####################

set CLK_PERIOD_DATA 17.00 
set CLK_LATENCY_DATA 1.00
set CLK_SKEW_DATA 0.50
set CLK_JITTER_DATA 0.20
set SETUP_UNCERTAINTY_DATA [expr $CLK_SKEW_DATA + $CLK_JITTER_DATA]
set INPUT_DELAY 1.00
set OUTPUT_DELAY 1.00

## Clock constraints
create_clock data_clk -period $CLK_PERIOD_DATA -waveform {0.0 8.5}
set_clock_latency $CLK_LATENCY_DATA data_clk
set_clock_uncertainty -setup $SETUP_UNCERTAINTY_DATA data_clk
set_clock_uncertainty -hold $CLK_SKEW_DATA data_clk
set_clock_transition -rise 0.1 data_clk
set_clock_transition -fall 0.12 data_clk

#####################
### Clock Domain Crossing
#####################

#set false paths between clock domains because we are handling them with cdc circuitry
set_false_path -from [get_clocks SCLK] -to [get_clocks sym_clk]
set_false_path -from [get_clocks sym_clk] -to [get_clocks SCLK]
set_false_path -from [get_clocks SCLK] -to [get_clocks data_clk]
set_false_path -from [get_clocks data_clk] -to [get_clocks SCLK]
set_false_path -from [get_clocks data_clk] -to [get_clocks sym_clk]
set_false_path -from [get_clocks sym_clk] -to [get_clocks data_clk]

######################
### Input/Output signals
######################

# Virtual clock for input/output signals
create_clock -name v_SCLK -period $CLK_PERIOD_SCLK -waveform {0.0 5000.0}
create_clock -name v_sym_clk -period $CLK_PERIOD_SYM -waveform {0.0 50.0}
create_clock -name v_data_clk -period $CLK_PERIOD_DATA -waveform {0.0 8.5}

# Max transition/capacitance
set_max_transition 1.5 [current_design]
set_max_capacitance 0.5 [current_design]

# Input constraints
set_input_delay $INPUT_DELAY -clock v_SCLK [get_ports MOSI]
set_input_delay $INPUT_DELAY -clock v_SCLK [get_ports CSN]
set_input_delay $INPUT_DELAY -clock v_data_clk [get_ports data_in]

set_max_fanout 1 [all_inputs]
set_input_transition -rise 0.1 [all_inputs]
set_input_transition -fall 0.12 [all_inputs]

# Outputs constraints
set_output_delay $OUTPUT_DELAY -clock v_SCLK [get_ports MISO]
set_output_delay $OUTPUT_DELAY -clock v_SCLK [get_ports MISO_enable]
set_load 0.2 [all_outputs]
