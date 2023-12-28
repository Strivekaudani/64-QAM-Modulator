#!/bin/bash

# list of design files to be compiled

ver_files=("../../source/modulator_64qam_top.v"
	  "../../source/baseband_data.v"
	  "../../source/control_fsm.v"
	  "../../source/spi_interface.v"
	  "../../source/symbol_mapping.v"
	  "../../source/symbol_storage.v"
	  "../../source/sync_ff_sync_1b.v"
	  "../../source/sync_fifo_10b.v"
	  "../../source/sync_fifo_ff_sync_4b.v"
	  "../../source/sync_fifo_read_counter.v"
	  "../../source/sync_fifo_reg_array_10b.v"
	  "../../source/sync_fifo_reg_array.v"
	  "../../source/sync_fifo_write_counter.v"
	  "../../source/sync_fifo.v"
	  "../../source/reset_synchronization.v"
	  "../testbench/modulator_64qam_top_tb.v")	
