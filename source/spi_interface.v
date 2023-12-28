`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator SPI Interface module
//
////////////////////////////////////////////////////////////////////////////

module spi_interface(
		     input wire	      SCLK,
		     input wire	      MOSI,
		     input wire	      CSN,
                     input wire	      rst_n,
		     input wire [7:0] reg_read_data,
		     input wire	      mapping,
		     input wire	      reg_addr_fifo_full,
		     input wire	      read_data_fifo_empty,
		     input wire       read_data_read_ready,
		     input wire       write_data_fifo_full,
		     output reg	      MISO,
		     output reg	      MISO_enable,
		     output reg	      enable,
		     output reg [9:0] reg_addr,
		     output reg [7:0] reg_write_data,
		     output reg	      reg_write_enable,
		     output reg	      reg_read_enable,
		     output reg       read_data_read_enable
		     );

   //internal registers
   reg [9:0]			       spi_shift_reg_current;
   reg [2:0]			       state_current;
   reg [5:0]			       bit_count_current;
   reg				       reg_rw_current;
   reg				       MISO_pos_edge;
   reg				       MISO_enable_pos_edge;
   reg [7:0]			       MISO_buffer_current;
   reg 				       first_loop;
   
   

   //internal combinational registers
   reg [9:0]			       spi_shift_reg_next;
   reg [2:0]			       state_next;
   reg [5:0]			       bit_count_next;
   reg				       reg_rw_next;
   reg				       MISO_next;
   reg				       MISO_enable_next;
   reg [9:0]			       reg_addr_next;
   reg [7:0]			       reg_write_data_next;
   reg				       reg_write_enable_next;
   reg				       reg_read_enable_next;
   reg [7:0]			       MISO_buffer_next;
   reg 				       first_loop_next;
   reg				       enable_next;
   reg                                 read_data_read_enable_next;
   

   //FSM Definition
   parameter [2:0]		       S0_IDLE = 3'b000;
   parameter [2:0]		       S1_RW = 3'b001;
   parameter [2:0]		       S2_REG_ADDR = 3'b010;
   parameter [2:0]		       S3_READ = 3'b011;
   parameter [2:0]		       S4_WRITE = 3'b100;
   parameter [2:0]		       S5_ENABLED = 3'b101;
   

   //sequential logic
   always @(posedge SCLK or negedge rst_n)
     begin
	if(rst_n == 1'b0) begin
	   state_current         <= S0_IDLE;
	   spi_shift_reg_current <= 9'd0;
	   bit_count_current     <= 6'd33;
	   reg_rw_current        <= 1'b0;
	   reg_addr              <= 8'h00;
	   MISO_pos_edge         <= 1'b0;
	   MISO_enable_pos_edge  <= 1'b0;
	   MISO_buffer_current   <= 8'h00;
	   reg_write_data        <= 8'h00;
	   reg_write_enable      <= 1'b0;
	   reg_read_enable       <= 1'b0;
	   first_loop            <= 1'b0;
	   enable                <= 1'b0;
	   read_data_read_enable <= 1'b0;
	end else begin // if (rst_n == 1'b0)
	   state_current         <= state_next;
	   spi_shift_reg_current <= spi_shift_reg_next;
	   bit_count_current     <= bit_count_next;
	   reg_rw_current        <= reg_rw_next;
	   reg_addr              <= 10'b1000000001;
	   MISO_pos_edge         <= MISO_next;
	   MISO_enable_pos_edge  <= MISO_enable_next;
	   MISO_buffer_current   <= MISO_buffer_next;
	   reg_write_data        <= reg_write_data_next;
	   reg_write_enable      <= reg_write_enable_next;
	   reg_read_enable       <= reg_read_enable_next;
	   first_loop            <= first_loop_next;
	   enable                <= enable_next;
	   read_data_read_enable <= read_data_read_enable_next;
	end // else: !if(rst_n == 1'b0)
     end // always @ (posedge SCLK or negedge rst_n)

   //falling edge logic for MISO
   always @(negedge SCLK or negedge rst_n)
     begin
	if(rst_n == 1'b0)begin
	   MISO <= 1'b0;
	   MISO_enable <= 1'b0;
	end else begin
	   MISO <= MISO_pos_edge;
	   MISO_enable <= MISO_enable_pos_edge;
	end
     end

   //combinational logic for MOSI shift register
   always @(*)
     begin
	spi_shift_reg_next = {spi_shift_reg_current[8:0], MOSI};
     end

   //combinational logic for state machine
   always @(*)
     begin
	state_next            = state_current;
	bit_count_next        = bit_count_current;
	reg_rw_next           = reg_rw_current;
	reg_addr_next         = reg_addr;
	reg_write_data_next   = reg_write_data;
	reg_write_enable_next = 1'b0;
	reg_read_enable_next  = 1'b0;
	MISO_enable_next      = MISO_enable_pos_edge;
	MISO_buffer_next      = MISO_buffer_current;
	MISO_next             = MISO_pos_edge;
	first_loop_next       = first_loop;
	enable_next           = enable;
	read_data_read_enable_next = read_data_read_enable;

	case(state_current)
	  S0_IDLE: begin
	     if(CSN == 1'b0)begin
		state_next = S1_RW;
		bit_count_next = bit_count_current - 1'b1;
	     end else begin
		reg_addr_next = 10'd512;
		reg_read_enable_next = 1'b1;
		//some clock cycles required
		MISO_buffer_next = reg_read_data;

		if(MISO_buffer_current[0] == 1'b1)begin
		   enable_next = 1'b1;
		   state_next = S5_ENABLED;
		end else begin
		   enable_next = 1'b0;
		end
	     end // else: !if(CSN == 1'b0)  
	  end // case: S0_IDLE

	  

	  S1_RW: begin
	     state_next = S2_REG_ADDR;
	     reg_rw_next = spi_shift_reg_current[0];
	     bit_count_next = bit_count_current - 1'b1;
	  end

	  S2_REG_ADDR: begin
	     bit_count_next = bit_count_current - 1'b1;
	     if(bit_count_current == 6'd23)begin
		if(reg_rw_current == 1'b0)begin
		   state_next = S3_READ;
		   first_loop_next = 1'b1;
		end else begin
		   state_next = S4_WRITE;
		end
		
		if(reg_addr_fifo_full == 1'b0)begin
		   reg_addr_next = spi_shift_reg_current;
		end
	     end
	  end // case: S2_REG_ADDR

	  S3_READ: begin
	     reg_read_enable_next = 1'b1;
	     
	     if(first_loop == 1'b1)begin
		if(read_data_read_ready == 1'b1)begin
		   read_data_read_enable_next = 1'b1;
		   if(read_data_fifo_empty == 1'b0)begin
		      MISO_buffer_next = reg_read_data;
		   end
		end
	     end else if(MISO_enable == 1'b1)begin
		MISO_next = MISO_buffer_current[7];
		MISO_buffer_next = {MISO_buffer_current[6:0], 1'b0};
	     end else begin
		enable_next = MISO_buffer_current[0];
	     end
	     
	     bit_count_next = bit_count_current - 1'b1;
	     
	     if(bit_count_current == 6'd18)begin
		MISO_enable_next = 1'b1;
		first_loop_next = 1'b0;
	     end else if(bit_count_current == 6'd0)begin
	        state_next = S0_IDLE;
	        bit_count_next = 6'd33;
	        MISO_enable_next = 1'b0;
	     end 
	  end

	  S4_WRITE: begin
	     bit_count_next = bit_count_current - 1'b1;
	     if(bit_count_current == 6'd6)begin
		if(write_data_fifo_full == 1'b0)begin
		   reg_write_enable_next = 1'b1;
		   reg_write_data_next = spi_shift_reg_current[7:0];
		end
	     end else if(bit_count_current == 6'd0)begin
		state_next = S0_IDLE;
		bit_count_next = 6'd33;
	     end
	  end // case: S4_WRITE

	  S5_ENABLED: begin
	     reg_write_enable_next = 1'b1;
	     reg_write_data_next = {6'b000000, mapping, enable};
	     //some clock cycles required
	     state_next = S0_IDLE;
	  end

	  default: begin
	     if(CSN == 1'b0)begin
		state_next = S1_RW;
		bit_count_next = bit_count_current - 1'b1;
	     end
	  end
	endcase // case (state_current)
     end // always @ (*)
   
endmodule // spi_interface
	     
		
	     
	     
   
	   
   
   
