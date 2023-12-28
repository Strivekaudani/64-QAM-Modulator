`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator 8-bit Sync Fifo top level module
//
////////////////////////////////////////////////////////////////////////////

module sync_fifo(
		 input wire	   clk_write,
		 input wire	   clk_read,
		 input wire	   rst_n_write,
		 input wire	   rst_n_read,
		 input wire [7:0]  write_data,
		 input wire	   write_enable,
		 input wire	   read_enable,
		 output wire [7:0] read_data,
		 output wire	   fifo_full,
		 output wire	   fifo_empty
    );

   // internal signals between write counter and reg array
   wire [2:0]		     write_addr;   
   wire			     write_enable_int;

   // internal signals between read counter and reg array
   wire [2:0]		     read_addr;
   wire			     read_enable_int;

   // gray coded write pointer synchronized to read clock domain
   wire [3:0]		     write_pointer_gray;
   wire [3:0]		     write_pointer_gray_sync_read;

   // gray coded write pointer synchronized to write clock domain
   wire [3:0]		     read_pointer_gray;
   wire [3:0]		     read_pointer_gray_sync_write;
   
   
   
   

   // register array
   sync_fifo_reg_array u_reg_array(
				   .clk_write(clk_write),
				   .rst_n_write(rst_n_write),
				   .write_data(write_data),
				   .write_addr(write_addr),
				   .write_enable(write_enable_int),
				   .clk_read(clk_read),
				   .rst_n_read(rst_n_read),
				   .read_addr(read_addr),
				   .read_enable(read_enable_int),
				   .read_data(read_data));

   // write counter
   sync_fifo_write_counter u_write_counter(
					   .clk(clk_write),
					   .rst_n(rst_n_write),
					   .write_enable(write_enable),
					   .read_pointer_gray(read_pointer_gray_sync_write),
					   .full(fifo_full),
					   .write_enable_out(write_enable_int),
					   .write_pointer(write_addr),
					   .write_pointer_gray(write_pointer_gray));

   // read counter
   sync_fifo_read_counter u_read_counter(
					 .clk(clk_read),
					 .rst_n(rst_n_read),
					 .read_enable(read_enable),
					 .write_pointer_gray(write_pointer_gray_sync_read),
					 .empty(fifo_empty),
					 .read_enable_out(read_enable_int),
					 .read_pointer(read_addr),
					 .read_pointer_gray(read_pointer_gray));

   // two flip-flop synchronizers to sync pointers across clock domains
   // synchronize write pointer to read clock domain
   sync_fifo_ff_sync_4b u_write_pointer_sync(
					     .clk(clk_read),
					     .rst_n(rst_n_read),
					     .data_in(write_pointer_gray),
					     .data_out(write_pointer_gray_sync_read));

   // synchronize read pointer to write clock domain
   sync_fifo_ff_sync_4b u_read_pointer_sync(
					     .clk(clk_write),
					     .rst_n(rst_n_write),
					     .data_in(read_pointer_gray),
					     .data_out(read_pointer_gray_sync_write));
   


  

endmodule
