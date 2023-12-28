`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator top level module
//
////////////////////////////////////////////////////////////////////////////

module modulator_64qam_top(
			   input wire  SCLK,
			   input wire  sym_clk,
			   input wire  data_clk,
			   input wire  data_in,
			   input wire  MOSI,
			   input wire  CSN,
			   input wire  rst_n,
			   output wire MISO,
			   output wire MISO_enable
			   );


   //reset synchronization
   //SPI reset synchronization signal
   wire				       rst_n_SPI;

   //data reset synchronization signal
   wire				       rst_n_data;

   //symbol reset synchronization signal
   wire				       rst_n_sym;

   //write enable two flip flop synchronized to symbol storage clock domain
   wire				       write_enable;
   wire				       write_enable_sync_sym;
   
   //read enable two flip flop synchronized to symbol storage clock domain
   wire				       read_enable;
   wire				       read_enable_sync_sym;

   //new symbol two flip flop synchronized to symbol storage clock domain
   wire				       new_symbol;
   wire				       new_symbol_sync_sym;

   //mapping two flip flop synchronized to SPI domain
   wire				       mapping;
   wire				       mapping_sync_spi;

   //enable two flip flop synchronized to data domain
   wire				       enable;
   wire				       enable_sync_data;
   
   //write data CDC FIFO synchronized to symbol storage clock domain
   wire [7:0]			       write_data;
   wire [7:0]			       write_data_sync_sym;
   wire				       write_data_read_enable;
   wire				       write_data_fifo_empty;
   wire				       write_data_fifo_full;

   //read data CDC FIFO synchronized to symbol storage clock domain
   wire [7:0]				       read_data;
   wire [7:0]				       read_data_sync_spi;
   wire					       read_data_write_enable;
   wire					       read_data_fifo_empty;
   wire					       read_data_fifo_full;
   wire 				       read_data_write_enable_sync_SPI;
   wire                                        read_data_read_enable;

   //i and q data CDC FIFO synchronized to symbol storage clock domain
   wire [3:0]				       i_data;
   wire [3:0]				       q_data;
   wire [3:0]				       i_data_sync_sym;
   wire [3:0]				       q_data_sync_sym;
   wire					       i_q_data_read_enable;
   wire					       i_q_data_fifo_empty;
   wire					       i_q_data_fifo_full;

   //reg address CDC FIFO synchronized to symbol storage clock domain
   wire [9:0]				       reg_addr;
   wire [9:0]				       reg_addr_sync_sym;
   reg					       reg_addr_write_enable;
   wire					       reg_addr_read_enable;
   wire					       reg_addr_fifo_empty;
   wire					       reg_addr_fifo_full;


   
   
   

   //interfacing
   
   //reset synchronization
   reset_synchronization u_reset_synchronization(
						  .SCLK(SCLK),
						  .data_clk(data_clk),
						  .sym_clk(sym_clk),
						  .rst_n(rst_n),
						  .rst_n_SPI(rst_n_SPI),
						  .rst_n_sym(rst_n_sym),
						  .rst_n_data(rst_n_data)
						  );
						  
   //////////////////////////////////////////////////////////////////////////////////////////
   //spi interface
   spi_interface u_spi_interface(
				 .SCLK(SCLK),
				 .MOSI(MOSI),
				 .CSN(CSN),
				 .rst_n(rst_n_SPI),
				 .reg_read_data(read_data_sync_spi),
				 .mapping(mapping_sync_spi),
				 .reg_addr_fifo_full(reg_addr_fifo_full),
				 .read_data_fifo_empty(read_data_fifo_empty),
				 .read_data_read_ready(read_data_write_enable_sync_SPI), /////////////////
				 .write_data_fifo_full(write_data_fifo_full),
				 .MISO(MISO),
				 .MISO_enable(MISO_enable),
				 .enable(enable),
				 .reg_addr(reg_addr),
				 .reg_write_data(write_data),
				 .reg_write_enable(write_enable),
				 .reg_read_enable(read_enable),
				 .read_data_read_enable(read_data_read_enable)
				 );

   //baseband data
   baseband_data u_baseband_data(
				 .data_clk(data_clk),
				 .rst_n(rst_n_data),
				 .data_in(data_in),
				 .enable(enable_sync_data),
				 .i_q_data_fifo_full(i_q_data_fifo_full),
				 .i_data(i_data),
				 .q_data(q_data),
				 .new_symbol(new_symbol),
				 .mapping(mapping)
				 );
				 


   //symbol storage 
   symbol_storage u_symbol_storage(
				   .sym_clk(sym_clk),
				   .rst_n(rst_n_sym),
				   .i_data_in(i_data_sync_sym),
				   .q_data_in(q_data_sync_sym),
				   .reg_addr(reg_addr_sync_sym),
				   .write_data(write_data_sync_sym),
				   .write_enable(write_enable_sync_sym),
				   .read_enable(read_enable_sync_sym),
				   .new_symbol(new_symbol_sync_sym),
				   .read_data_fifo_full(read_data_fifo_full),
				   .write_data_fifo_empty(write_data_fifo_empty),
				   .reg_addr_fifo_empty(reg_addr_fifo_empty),
				   .i_q_data_fifo_empty(i_q_data_fifo_empty),
				   .read_data(read_data),
				   .read_data_fifo_write_enable(read_data_write_enable),
				   .write_data_fifo_read_enable(write_data_read_enable),
				   .reg_addr_fifo_read_enable(reg_addr_read_enable),
				   .i_q_data_fifo_read_enable(i_q_data_read_enable)
				   );
   
   //CHECK THESE INTERFACES WITH A FRESH MIND
				   
   ////////////////////////////////////////////////////////////////////////////////////////////////////		   
				 
				 


   //synchronize signals between SPI clock domain and symbol storage clock domain
   //synchronize write enable to symbol storage clock domain
   sync_ff_sync_1b u_write_enable_sync(
					    .clk(sym_clk),
					    .rst_n(rst_n_sym),
					    .data_in(write_enable),
					    .data_out(write_enable_sync_sym)
					    );

   sync_ff_sync_1b u_read_enable_sync(
					   .clk(sym_clk),
					   .rst_n(rst_n_sym),
					   .data_in(read_enable),
					   .data_out(read_enable_sync_sym)
					   );
					
   sync_ff_sync_1b u_read_ready_sync(
					   .clk(SCLK),
					   .rst_n(rst_n_SPI),
					   .data_in(read_data_write_enable),
					   .data_out(read_data_write_enable_sync_SPI)
					   );

   //synchronize write data CDC FIFO between SPI clock domain and symbol storage clock domain
   sync_fifo u_write_data(
			  .clk_write(SCLK),
			  .clk_read(sym_clk),
			  .rst_n_write(rst_n_SPI),
			  .rst_n_read(rst_n_sym),
			  .write_data(write_data),
			  .write_enable(write_enable),
			  .read_enable(write_data_read_enable),
			  .read_data(write_data_sync_sym),
			  .fifo_full(write_data_fifo_full),
			  .fifo_empty(write_data_fifo_empty)
			  );

   //synchronize read data CDC FIFO between SPI clock domain and symbol storage clock domain
   sync_fifo u_read_data(
			  .clk_write(sym_clk),
			  .clk_read(SCLK),
			  .rst_n_write(rst_n_sym),
			  .rst_n_read(rst_n_SPI),
			  .write_data(read_data),
			  .write_enable(read_data_write_enable),
			  .read_enable(read_data_read_enable),
			  .read_data(read_data_sync_spi),
			  .fifo_full(read_data_fifo_full),
			  .fifo_empty(read_data_fifo_empty)
			  );

   sync_fifo_10b u_reg_addr(
			  .clk_write(SCLK),
			  .clk_read(sym_clk),
			  .rst_n_write(rst_n_SPI),
			  .rst_n_read(rst_n_sym),
			  .write_data(reg_addr),
			  .write_enable(reg_addr_write_enable),
			  .read_enable(reg_addr_read_enable),
			  .read_data(reg_addr_sync_sym),
			  .fifo_full(reg_addr_fifo_full),
			  .fifo_empty(reg_addr_fifo_empty)
			  );

   //synchronize register address CDC FIFO between SPI clock domain and symbol storage clock domain
   
 
   //synchronize signals between baseband data clock domain and symbol storage clock domain
   //synchronize new symbol to symbol storage clock domain
   sync_ff_sync_1b u_new_symbol_sync(
					  .clk(sym_clk),
					  .rst_n(rst_n_sym),
					  .data_in(new_symbol),
					  .data_out(new_symbol_sync_sym)
					  );

   //synchronize i and q data CDC FIFO between baseband data clock domain and symbol storage clock domain
   sync_fifo u_i_q_data(
			  .clk_write(data_clk),
			  .clk_read(sym_clk),
			  .rst_n_write(rst_n_data),
			  .rst_n_read(rst_n_sym),
			  .write_data({i_data, q_data}),
			  .write_enable(new_symbol),
			  .read_enable(i_q_data_read_enable),
			  .read_data({i_data_sync_sym, q_data_sync_sym}),
			  .fifo_full(i_q_data_fifo_full),
			  .fifo_empty(i_q_data_fifo_empty)
			  );


  //synchronize signals between baseband data clock domain and SPI clock domain
  //synchronize mapping to SPI clock domain
  sync_ff_sync_1b u_mapping_sync(
					   .clk(SCLK),
					   .rst_n(rst_n_SPI),
					   .data_in(mapping),
					   .data_out(mapping_sync_spi)
					   );

  sync_ff_sync_1b u_enable_sync(
					   .clk(SCLK),
					   .rst_n(rst_n_SPI),
					   .data_in(enable),
					   .data_out(enable_sync_data)
					   );

  //combinational logic for enabling register address CDC FIFO either for read or write purposes
  always @(*)
    begin
       if((write_enable == 1'b1) | (read_enable == 1'b1))begin
	  reg_addr_write_enable = 1'b1;
       end else begin
	  reg_addr_write_enable = 1'b0;
       end
    end
    		  
endmodule // modulator_64qam_top

			 
			   
