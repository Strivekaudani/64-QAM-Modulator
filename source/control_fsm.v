`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator Control FSM module
//
////////////////////////////////////////////////////////////////////////////

module control_fsm(
		   input wire data_clk,
		   input wire data_in,
		   input wire rst_n,
		   input wire enable,
		   output reg enable_fsm,
		   output reg mapping
		   );

   //internal registers: shift register, counter, fsm state, header
   reg [11:0]		      baseband_shift_reg_current;
   reg [11:0]		      bit_count_current;
   reg  		      state_current;
   reg [11:0]		      checksum;
   reg [11:0]                 packet_header;
   

   //internal combinational logic
   reg			      enable_fsm_next;
   reg			      mapping_next;
   reg [11:0]		      baseband_shift_reg_next;
   reg [11:0]		      bit_count_next;
   reg   		      state_next;

   //FSM Definition
   parameter	      S0_HEADER = 1'b0;
   parameter	      S1_MAPPING = 1'b1;

   //sequential logic
   always @(posedge data_clk or negedge rst_n)
     begin
	if(rst_n == 1'b0)begin
	   enable_fsm                 <= 1'b0;
	   baseband_shift_reg_current <= 11'b00000000000;
	   bit_count_current          <= 12'd3083;
	   checksum                   <= 12'b101100111000;
	   state_current              <= S0_HEADER;
	   packet_header              <= 12'b000000000000;
	   mapping                    <= 1'b0;
	end else begin
	   enable_fsm                 <= enable_fsm_next;
	   baseband_shift_reg_current <= baseband_shift_reg_next;
	   bit_count_current          <= bit_count_next;
	   state_current              <= state_next;
	   mapping                    <= mapping_next;
	end
     end

   //combinational logic for Baseband shift register
   always @(*)
     begin
	if(enable == 1'b1)begin
	   baseband_shift_reg_next = {baseband_shift_reg_current[10:0], data_in};
	end
     end

   //combinational logic for fsm
   always @(*)
     begin
	enable_fsm_next = enable_fsm;
	bit_count_next  = bit_count_current;
	state_next      = state_current;
	mapping_next    = mapping;

	if(enable == 1'b1)begin

	   case(state_current)

	     S0_HEADER: begin
		bit_count_next = bit_count_current - 1'b1;

		if(bit_count_current == 12'd3071)begin
	           packet_header = baseband_shift_reg_current;
		   if(checksum == packet_header)begin
		      enable_fsm_next = 1'b1;
		      mapping_next    = 1'b1;
		      state_next      =  S1_MAPPING;
		   end
		end else if(bit_count_current == 12'd0) begin
	           bit_count_next = 12'd3083;
		end
	     end

	     S1_MAPPING: begin
		bit_count_next = bit_count_current -1'b1;

		if(bit_count_current == 12'd0)begin
		   enable_fsm_next = 1'b0;
		   mapping_next    = 1'b0;
		   state_next      = S0_HEADER;
		   bit_count_next  = 12'd3083;
		end
	     end

	     default: begin
		enable_fsm_next = 1'b0;
		state_next      = S0_HEADER;
		bit_count_next  = 12'd3083;
		mapping_next    = 1'b0;
	     end
	     
	   endcase // case (state_current)

	end // if (enable == 1'b1)

     end // always @ (*)
     
endmodule

   
	
	     

	       
		   
	    

	

	
	
   
