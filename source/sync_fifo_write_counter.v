`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator Sync FIFO write counter module
//
////////////////////////////////////////////////////////////////////////////

module sync_fifo_write_counter(
	       input wire	clk,
	       input wire	rst_n,
	       input wire	write_enable,
	       input wire [3:0]	read_pointer_gray,
	       output reg	full,
	       output reg	write_enable_out,
	       output reg [2:0]	write_pointer,
	       output reg [3:0]	write_pointer_gray
    );

   // internal registers
   reg [3:0]		     write_pointer_full;

   // internal combinational variables
   reg [3:0]		     write_pointer_next;
   reg [3:0]		     write_pointer_gray_next;
   reg [3:0]		     read_pointer;
   reg			     full_next;			     
		     
   // sequential logic, active-low asynch reset
   always @(posedge clk or negedge rst_n)
     begin
	if (rst_n == 1'b0) begin
	   // reset all registers to default values
	   write_pointer_full <= 4'h0;
	   write_pointer_gray <= 4'h0;
	   full               <= 1'b0;
	end else begin
	   write_pointer_full <= write_pointer_next;
	   write_pointer_gray <= write_pointer_gray_next;
	   full               <= full_next;
	end // else: !if(rst_n == 1'b0)
     end // always @ (posedge clk or negedge rst_n)

   // combinational logic
   always @(*)
     begin
	// assign default values to all comb variables
	write_enable_out        = 1'b0;
	write_pointer           = write_pointer_full[2:0];
	write_pointer_next      = write_pointer_full; 
	
	// fifo write logic
	if ( (write_enable == 1'b1) & (full == 1'b0) ) begin
	   write_enable_out    = 1'b1;
	   write_pointer_next  = write_pointer_full + 1'b1;
	end	
	
     end // always @ (*)

   // combinational logic to convert write pointer to gray code
   always @(*)
     begin
	write_pointer_gray_next = write_pointer_next[3:0] ^ {1'b0, write_pointer_next[3:1]};
     end

   // convert read pointer from gray code to binary
   always @(*)
     begin
	read_pointer[3] = read_pointer_gray[3];
	read_pointer[2] = read_pointer_gray[3] ^ read_pointer_gray[2];
	read_pointer[1] = read_pointer_gray[3] ^ read_pointer_gray[2] ^ read_pointer_gray[1];
	read_pointer[0] = read_pointer_gray[3] ^ read_pointer_gray[2] ^ read_pointer_gray[1] ^ read_pointer_gray[0];
     end

   // combinational full logic
   always @(*)
     begin
	// fifo full logic
	if ( (write_pointer_next[2:0] == read_pointer[2:0]) && (write_pointer_next[3] !=  read_pointer[3]) )
	  full_next = 1'b1;
	else
	  full_next = 1'b0;
     end
  

endmodule
