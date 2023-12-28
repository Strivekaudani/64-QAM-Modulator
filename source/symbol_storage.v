`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////
//
// Munya Kaudani
// 64-QAM Modulator Symbol Storage module
//
////////////////////////////////////////////////////////////////////////////

module symbol_storage(
		      input wire       sym_clk,
		      input wire       rst_n,
		      input wire [3:0] i_data_in,
		      input wire [3:0] q_data_in,
		      input wire [9:0] reg_addr,
		      input wire [7:0] write_data,
		      input wire       write_enable,
		      input wire       read_enable,
		      input wire       new_symbol,
		      input wire       read_data_fifo_full,
		      input wire       write_data_fifo_empty,
		      input wire       reg_addr_fifo_empty,
		      input wire       i_q_data_fifo_empty,
		      output reg [7:0] read_data,
		      output reg       read_data_fifo_write_enable,
		      output reg       write_data_fifo_read_enable,
		      output reg       reg_addr_fifo_read_enable,
		      output reg       i_q_data_fifo_read_enable
		      );

   //internal registers
   reg [7:0]			       register_array_data_current[0:513];
   reg [9:0]			       write_addr_pointer;
   reg [1:0]			       state_current;
   reg [7:0]                           SCLK_sync_counter;
   
   //internal combinational variables
   reg [7:0]			       register_array_data_next[0:513];
   reg [7:0]			       read_data_next;
   reg				       read_data_fifo_write_enable_next;
   reg				       write_data_fifo_read_enable_next;
   reg				       reg_addr_fifo_read_enable_next;
   reg				       i_q_data_fifo_read_enable_next;
   reg [9:0]			       write_addr_pointer_next;
   reg [1:0]			       state_next;
   reg [7:0]                           SCLK_sync_counter_next;

   //loop variables
   integer			       i;
   integer			       j;

   //FSM Definition
   parameter [1:0]		       S0_IDLE    = 2'b00;
   parameter [1:0]		       S1_WRITING = 2'b01;
   parameter [1:0]		       S2_READING = 2'b10;
   parameter [1:0]		       S3_MAPPING = 2'b11;
   

   //sequential logic
   always @(posedge sym_clk or negedge rst_n)
     begin
	if(rst_n == 1'b0)begin
	   read_data                         <= 8'h00;
	   read_data_fifo_write_enable       <= 1'b0;
	   write_data_fifo_read_enable       <= 1'b0;
	   reg_addr_fifo_read_enable         <= 1'b0;
	   i_q_data_fifo_read_enable         <= 1'b0;
	   write_addr_pointer                <= 10'd0;
	   state_current                     <= S0_IDLE;
	   SCLK_sync_counter                 <= 8'd150;
	   for(i = 0; i <= 513; i = i + 1)begin
	      register_array_data_current[i] <= 8'h00;
	   end
	end else begin
	   read_data                         <= read_data_next;
	   read_data_fifo_write_enable       <= read_data_fifo_write_enable_next;
	   write_data_fifo_read_enable       <= write_data_fifo_read_enable_next;
	   reg_addr_fifo_read_enable         <= reg_addr_fifo_read_enable_next;
	   i_q_data_fifo_read_enable         <= i_q_data_fifo_read_enable_next;
	   write_addr_pointer                <= write_addr_pointer_next;
	   state_current                     <= state_next;
	   SCLK_sync_counter                 <= SCLK_sync_counter_next;
	   for(i = 0; i <= 513; i = i + 1)begin
	      register_array_data_current[i] <= register_array_data_next[i];
	   end
	end // else: !if(rst_n == 1'b0)
     end // always @ (posedge sym_clk or negedge rst_n)

   //combinational logic
   always @(*)
     begin
	read_data_next = read_data;
	read_data_fifo_write_enable_next = read_data_fifo_write_enable;
	write_data_fifo_read_enable_next = write_data_fifo_read_enable;
	reg_addr_fifo_read_enable_next = reg_addr_fifo_read_enable;
	i_q_data_fifo_read_enable_next = i_q_data_fifo_read_enable;
	write_addr_pointer_next =  write_addr_pointer;
	state_next = state_current;
	SCLK_sync_counter_next = SCLK_sync_counter;
	for(j = 0; j <= 513; j = j + 1)begin
	   register_array_data_next[j] = register_array_data_current[j];
	end

	case(state_current)
	  S0_IDLE: begin
	     if((write_enable == 1'b1) & (write_data_fifo_empty == 1'b0))begin
		write_data_fifo_read_enable_next = 1'b1;
		reg_addr_fifo_read_enable_next = 1'b1;
		state_next = S1_WRITING;
	     end

	     if((read_enable == 1'b1) & (read_data_fifo_full == 1'b0))begin
		read_data_fifo_write_enable_next = 1'b1;
		reg_addr_fifo_read_enable_next = 1'b1;
		state_next = S2_READING;
	     end
	     
	     if((new_symbol == 1'b1) & (i_q_data_fifo_empty == 1'b0))begin
		i_q_data_fifo_read_enable_next = 1'b1;
		state_next = S3_MAPPING;
	     end
	  end // case: S0_IDLE

	  S1_WRITING: begin
	     register_array_data_next[reg_addr] = write_data;
	     state_next = S0_IDLE;
	     write_data_fifo_read_enable_next = 1'b0;
	     reg_addr_fifo_read_enable_next = 1'b0;
	  end

	  S2_READING: begin
	     SCLK_sync_counter_next = SCLK_sync_counter - 1'b1;
	     
	     if(SCLK_sync_counter == 8'd0)begin
	       read_data_next = register_array_data_current[reg_addr];
	       state_next = S0_IDLE;
	       read_data_fifo_write_enable_next = 1'b0;
	       reg_addr_fifo_read_enable_next = 1'b0;
	       SCLK_sync_counter_next = 8'd150;
	     end
	  end

	  S3_MAPPING: begin
	     register_array_data_next[write_addr_pointer] = {i_data_in, q_data_in};
	     write_addr_pointer_next = write_addr_pointer + 1'b1;
	     state_next = S0_IDLE;
	     i_q_data_fifo_read_enable_next = 1'b0;
	     
	     if(write_addr_pointer == 10'd511)begin
		write_addr_pointer_next = 10'd0;
	     end
	  end

	endcase // case (state_current)

     end // always @ (*)

endmodule // symbol_storage

   

      
	
   

	  
	   

	

	
	   
	
