`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator Reset Synchronization module
//
////////////////////////////////////////////////////////////////////////////

module reset_synchronization(
			     input wire SCLK,
			     input wire data_clk,
			     input wire sym_clk,
			     input wire rst_n,
			     output reg rst_n_SPI,
			     output reg rst_n_sym,
			     output reg rst_n_data
			     );

   //SPI reset internal registers
   reg					SPI_data_mid;
   reg					SPI_data_in;

   //data reset internal registers
   reg					data_data_mid;
   reg					data_data_in;

   //symbol reset internal registers
   reg					sym_data_mid;
   reg					sym_data_in;
   
   
   //SPI reset synchronization
   always @(posedge SCLK or negedge rst_n)
     begin
	if(rst_n == 1'b0)begin
	   rst_n_SPI <= 1'b0;
	   SPI_data_mid <= 1'b0;
	   SPI_data_in <= 1'b1;
	end else begin
	   rst_n_SPI <= SPI_data_mid;
	   SPI_data_mid <= SPI_data_in;
	end
     end // always @ (posedge SCLK or negedge rst_n)

   //data reset synchronization
   always @(posedge data_clk or negedge rst_n)
      begin
	 if(rst_n == 1'b0)begin
	    rst_n_data <= 1'b0;
	    data_data_mid <= 1'b0;
	    data_data_in <= 1'b1;
	 end else if((rst_n == 1'b1) & (rst_n_SPI == 1'b1))begin
	    rst_n_data <= data_data_mid;
	    data_data_mid <= data_data_in;
	 end
      end // always @ (posedge data_clk or negedge rst_n)

   //symbol reset synchronization
   always @(posedge sym_clk or negedge rst_n)
     begin
	if(rst_n == 1'b0)begin
	   rst_n_sym <= 1'b0;
	   sym_data_mid <= 1'b0;
	   sym_data_in <= 1'b1;
	end else if((rst_n == 1'b1) & (rst_n_data))begin
	   rst_n_sym <= sym_data_mid;
	   sym_data_mid <= sym_data_in;
	end
     end // always @ (posedge sym_clk or negedge rst_n)

endmodule // reset_synchronization

   
	   
	    
