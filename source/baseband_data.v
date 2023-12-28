`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator Baseband Data module
//
////////////////////////////////////////////////////////////////////////////

module baseband_data(
	   input wire	     data_clk,
	   input wire	     rst_n,
	   input wire	     data_in,
	   input wire	     enable,
	   input wire        i_q_data_fifo_full,
	   output wire [3:0] i_data,
	   output wire [3:0] q_data,
	   output wire	     new_symbol,
	   output wire	     mapping			  
	   );

   //internal signals
   wire		       enable_fsm;

   control_fsm control(
		       .data_clk(data_clk),
		       .rst_n(rst_n),
		       .data_in(data_in),
		       .enable_fsm(enable_fsm),
		       .enable(enable),
		       .mapping(mapping)
		       );

   symbol_mapping mapper(
			 .data_clk(data_clk),
			 .rst_n(rst_n),
			 .data_in(data_in),
			 .enable_fsm(enable_fsm),
			 .i_q_data_fifo_full(i_q_data_fifo_full),
			 .i_data(i_data),
			 .q_data(q_data),
			 .new_symbol(new_symbol)
			 );
endmodule // top

	   
