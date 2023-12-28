`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator Symbol Mapping module
//
////////////////////////////////////////////////////////////////////////////

module symbol_mapping(
		      input wire       data_clk,
		      input wire       rst_n,
		      input wire       data_in,
		      input wire       enable_fsm,
		      input wire       i_q_data_fifo_full,
		      output reg [3:0] i_data,
		      output reg [3:0] q_data,
		      output reg       new_symbol
		      );

   //internal registers
   reg [5:0]			  baseband_shift_reg_current;
   reg [2:0]			  bit_count_current;
   reg [3:0]			  i_value;
   reg [3:0]			  q_value;
   reg [3:0]			  i_mapped;
   reg [3:0]			  q_mapped;
   reg				  state_current;
   reg [2:0]                      lower_bits;
   reg [2:0]                      upper_bits;
   
   //internal combinational registers
   reg [5:0]			  baseband_shift_reg_next;
   reg [2:0]			  bit_count_next;
   reg [3:0]			  i_data_next;
   reg [3:0]			  q_data_next;
   reg				  new_symbol_next;
   reg				  state_next;

   //FSM Definition
   parameter			  S0_IDLE = 1'b0;
   parameter			  S1_MAPPING = 1'b1;
   
   //sequential logic
   always @(posedge data_clk or negedge rst_n)
     begin
	if(rst_n == 1'b0)begin
	   baseband_shift_reg_current <= 5'b00000;
	   bit_count_current          <= 3'd5;
	   i_data                     <= 4'b0000;
	   q_data                     <= 4'b0000;
	   new_symbol                 <= 1'b0;
	   state_current              <= S0_IDLE;
	   i_mapped                   <= 4'b0000;
	   q_mapped                   <= 4'b0000;
	   i_value                    <= 4'b0000;
	   q_value                    <= 4'b0000;
	   lower_bits                 <= 3'b000;
	   upper_bits                 <= 3'b000;
	end else begin
	   baseband_shift_reg_current <= baseband_shift_reg_next;
	   bit_count_current          <= bit_count_next;
	   i_data                     <= i_data_next;
	   q_data                     <= q_data_next;
	   new_symbol                 <= new_symbol_next;
	   state_current              <= state_next;

	end
     end


   //combinational logic for baseband shift register
   always @(*)
     begin
	baseband_shift_reg_next = {baseband_shift_reg_current[4:0], data_in};
     end

   //combinational logic
   always @(*)
     begin
	bit_count_next  = bit_count_current;
	i_data_next    = i_data;
	q_data_next    = q_data;
	state_next = state_current;
	new_symbol_next = 1'b0;

	case(state_current)
	  S0_IDLE: begin
	     if((enable_fsm == 1'b1) & (i_q_data_fifo_full == 1'b0))begin
		state_next = S1_MAPPING;
		bit_count_next = bit_count_current - 1'b1;
	     end else begin
	        i_data_next = 4'b0000;
		q_data_next = 4'b0000;
	     end
	  end

	  S1_MAPPING: begin
	     bit_count_next = bit_count_current - 1'b1;
	     if(bit_count_current == 3'd0)begin
	     
		lower_bits = baseband_shift_reg_current[2:0];
		upper_bits = baseband_shift_reg_current[5:3];
		case(upper_bits)
		  3'b000: i_value = -4'd7;
		  3'b001: i_value = -4'd5;
		  3'b010: i_value = -4'd3;
		  3'b011: i_value = -4'd1;
		  3'b100: i_value = 4'd1;
		  3'b101: i_value = 4'd3;
		  3'b110: i_value = 4'd5;
		  3'b111: i_value = 4'd7;
		  default: i_value = -4'd7;
		endcase // case (baseband_shift_reg_current[5:3])
		
		case(lower_bits)
		  3'b000: q_value = -4'd7;
		  3'b001: q_value = -4'd5;
		  3'b010: q_value = -4'd3;
		  3'b011: q_value = -4'd1;
		  3'b100: q_value = 4'd1;
		  3'b101: q_value = 4'd3;
		  3'b110: q_value = 4'd5;
		  3'b111: q_value = 4'd7;
		  default: q_value = -4'd7;
		endcase // case (baseband_shift_reg_current[5:3])

		i_mapped   = ~i_value;
		q_mapped   = ~q_value;
	      
		i_data_next     = i_mapped + 1'b1;
		q_data_next     = q_mapped + 1'b1;
		new_symbol_next = 1'b1;
		bit_count_next  = 3'd5;
		state_next      = S0_IDLE;
	     end // if (bit_count_current == 3'd0)	     
          end // case: S1_MAPPING

	  default: begin
	     state_next     = S0_IDLE;
	     bit_count_next = 3'd5;
	  end

	endcase // case (state_current)
	
     end // always @ (*)

endmodule // symbol_mapping

	   

	

	

	


	   
   
