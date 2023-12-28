`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator Sync FIFO read counter module
//
////////////////////////////////////////////////////////////////////////////

module sync_fifo_read_counter(
	       input wire	clk,
	       input wire	rst_n,
	       input wire	read_enable,
	       input wire [3:0]	write_pointer_gray,
	       output reg	empty,
	       output reg	read_enable_out,
	       output reg [2:0]	read_pointer,
	       output reg [3:0]	read_pointer_gray
    );

   // internal registers
   reg [3:0]		     read_pointer_full;

   // internal combinational variables
   reg [3:0]		     read_pointer_next;
   reg [3:0]		     read_pointer_gray_next;
   reg [3:0]		     write_pointer;
   reg			     empty_next;			     
		     
   // sequential logic, active-low asynch reset
   always @(posedge clk or negedge rst_n)
     begin
	if (rst_n == 1'b0) begin
	   // reset all registers to default values
	   read_pointer_full   <= 4'h0;
	   read_pointer_gray   <= 4'h0;
	   empty               <= 1'b0;
	end else begin
	   read_pointer_full   <= read_pointer_next;
	   read_pointer_gray   <= read_pointer_gray_next;
	   empty               <= empty_next;
	end // else: !if(rst_n == 1'b0)
     end // always @ (posedge clk or negedge rst_n)

   // combinational logic
   always @(*)
     begin
	// assign default values to all comb variables
	read_enable_out        = 1'b0;
	read_pointer           = read_pointer_full[2:0];
	read_pointer_next      = read_pointer_full; 
	
	// fifo read logic
	if ( (read_enable == 1'b1) & (empty == 1'b0) ) begin
	   read_enable_out    = 1'b1;
	   read_pointer_next  = read_pointer_full + 1'b1;
	end	
	
     end // always @ (*)

   // combinational logic to convert read pointer to gray code
   always @(*)
     begin
	read_pointer_gray_next = read_pointer_next[3:0] ^ {1'b0, read_pointer_next[3:1]};
     end

   // convert write pointer from gray code to binary
   always @(*)
     begin
	write_pointer[3] = write_pointer_gray[3];
	write_pointer[2] = write_pointer_gray[3] ^ write_pointer_gray[2];
	write_pointer[1] = write_pointer_gray[3] ^ write_pointer_gray[2] ^ write_pointer_gray[1];
	write_pointer[0] = write_pointer_gray[3] ^ write_pointer_gray[2] ^ write_pointer_gray[1] ^ write_pointer_gray[0];
     end

   // combinational empty logic
   always @(*)
     begin
	// fifo empty logic
	if (read_pointer_next[3:0] == write_pointer[3:0])
	  empty_next = 1'b1;
	else
	  empty_next = 1'b0;
     end
  

endmodule
