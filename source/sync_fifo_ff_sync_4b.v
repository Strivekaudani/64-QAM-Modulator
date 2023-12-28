`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator 4-bit two flip flop synchronizer module
//
////////////////////////////////////////////////////////////////////////////

module sync_fifo_ff_sync_4b(
	    input wire	     clk,
	    input wire	     rst_n,
	    input wire [3:0] data_in,
	    output reg [3:0] data_out
    );

   // internal registers
   reg [3:0]		     data_mid;

   // write sequential logic, active-low asynch reset
   always @(posedge clk or negedge rst_n)
     begin
	if (rst_n == 1'b0) begin
	   // reset all registers to default values
	   data_out <= 4'h0;
	   data_mid <= 4'h0;
	end else begin
	   data_out <= data_mid;
	   data_mid <= data_in;
	end // else: !if(rst_n == 1'b0)
     end // always @ (posedge clk or negedge rst_n)

endmodule
