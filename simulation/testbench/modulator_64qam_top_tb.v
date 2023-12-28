`timescale 1ns / 1ps

module modulator_64qam_top_tb(
			      );

   //SPI interface_signals
   reg              SCLK     = 1'b0;
   reg		    data_clk = 1'b0;
   reg		    sym_clk  = 1'b0;
   reg		    data_in  = 1'b0;
   reg		    MOSI     = 1'b0;
   reg		    CSN      = 1'b1;
   reg		    rst_n    = 1'b0;
   wire		    MISO;
   wire		    MISO_enable;

   // signal for SPI data output
   reg [7:0]	    SPI_data_out;

   //signals for simulation control
   reg		    tb_clk = 1'b0;
   reg [7:0]	    error_count;
   reg [8*39:0]	    testcase;
   reg [2:0]        lower_bits;
   reg [2:0]        upper_bits;
   reg [5:0]        buffer;
   reg [3:0]        i_value;
   reg [3:0]        q_value;
   reg [7:0]	    i_q_data_expected[0:513];
   reg [9:0]	    test_data_address       = 10'd513;
   reg [9:0]	    mapping_control_address = 10'd512;
   reg [7:0]	    mapping_control_data;
   
   
   // signal to save generated SPI data in
   reg [7:0]	    spi_data;

   //register to save generated baseband data in
   reg [5:0]    baseband_data[0:513];

   //loop variables
   integer	    i;

   //instantiate DUT
   modulator_64qam_top DUT(
			   .SCLK(SCLK),
			   .sym_clk(sym_clk),
			   .data_clk(data_clk),
			   .data_in(data_in),
			   .MOSI(MOSI),
			   .CSN(CSN),
			   .rst_n(rst_n),
			   .MISO(MISO),
			   .MISO_enable(MISO_enable)
			   );

   // 100kHz SCLK clk = 10 000ns period
   always #5000 tb_clk    = ~tb_clk;

   //60MHz data clk = 16.667ns period
   always #8.333 data_clk = ~data_clk;

   //10MHz symbol storage clock = 100ns period
   always #50 sym_clk     = ~sym_clk;
   
   initial begin
      testcase = "Initializing";
      repeat(10) 
	@(posedge data_clk);
      rst_n = 1'b1;
      
      @(posedge tb_clk)
	SCLK = 1'b1;
      @(negedge tb_clk)
	SCLK = 1'b0;

      // generate spi data to write and read back
      spi_data = $random;

      //generate baseband data to transmit
      for(i = 0; i <= 513; i = i + 1)begin
	 baseband_data[i] = $random;
      end

      //generate symbol mapped data for comparison with actual symbol mapped data
      for(i = 2; i <= 513; i = i + 1)begin
	 buffer     = baseband_data[i];
	 lower_bits = buffer[2:0];
	 upper_bits = buffer[5:3];
	 
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
	endcase // case (lower_bits)
	
	i_value = ~i_value;
	q_value = ~q_value;
	
	i_q_data_expected[i+1] = {(i_value + 1'b1), (q_value + 1'b1)};
      end // for (i = 2; i <= 513; i = i + 1)
  
      repeat(10)
	@(posedge data_clk);

      //SPI test data
      //write SPI test data to register address 513
      testcase = "SPI_WRITE";
      SPI_CMD(1'b1, test_data_address, spi_data, SPI_data_out);
      
      repeat(10)
	@(posedge data_clk);

      //read SPI test data from register address 513
      testcase = "SPI_READ";
      SPI_CMD(1'b0, test_data_address, spi_data, SPI_data_out);
      error_count = compare_outputs(spi_data, SPI_data_out, test_data_address, error_count);
      
      repeat(10)
	@(posedge data_clk);

      //Mapping control test
      //write 0 to register address 512 to disable mapping
      testcase = "SPI_MAPPING_DISABLE";
      mapping_control_data = 8'h00;
      SPI_CMD(1'b1, mapping_control_address, mapping_control_data, SPI_data_out);

      //transmit baseband data packets when mapping is disabled
      testcase = "MAPPING_DISABLED";
      baseband_data[0] = 6'b101100;
      baseband_data[1] = 6'b111000;
      for(i = 0; i <= 513; i = i + 1)begin
	baseband_CMD(baseband_data[i]);
      end

      repeat(10)
	@(posedge tb_clk);

      //write 1 to register address 512 to enable mapping
      testcase = "SPI_MAPPING_ENABLE";
      mapping_control_data = 8'h01;
      SPI_CMD(1'b1, mapping_control_address, mapping_control_data, SPI_data_out);

      //transmit baseband data packets when mapping is enabled
      //transmit baseband data packets with correct header
      testcase = "Correct Header";
      baseband_data[0] = 6'b101100;
      baseband_data[1] = 6'b111000;
      for(i = 0; i <= 513; i = i + 1)begin
	baseband_CMD(baseband_data[i]);
	SPI_CMD(1'b0, 10'd512, spi_data, SPI_data_out); //read address 512 to see if mapping in progress
      end

      repeat(10)
	@(posedge tb_clk);

      //transmit baseband data packets with incorrect header
      testcase = "Incorrect Header";
      baseband_data[0] = 6'b101010;
      baseband_data[1] = 6'b101010;
      for(i = 0; i <= 513; i = i + 1)begin
	baseband_CMD(baseband_data[i]);
        SPI_CMD(1'b0, 10'd512, spi_data, SPI_data_out); //read address 512 to see if mapping in progress
      end

      repeat(10)
	@(posedge tb_clk);

      // read all 512 registers via SPI
      testcase = "SPI_READ";
      for(i = 0; i <= 511; i = i + 1)begin
	 SPI_CMD(1'b0, i, spi_data, SPI_data_out);
	 error_count = compare_outputs(i_q_data_expected[i], SPI_data_out, i, error_count);
      end

      $display("Error Count = %d ", error_count); 
      

      repeat(20)
	@(posedge tb_clk);

      $finish;
   end // initial begin

   task SPI_CMD(
		input         SPI_read_write,
		input  [9:0]  SPI_addr,
		input  [7:0] SPI_data_in,
		output [7:0] SPI_data_out
		);

      integer		      i;
      
      begin

	 // active-low CSN active at clock negative edge, send read/write bit
	 @(negedge tb_clk)
	   CSN = 1'b0;

	 MOSI = SPI_read_write;
	 @(posedge tb_clk)
	   SCLK = 1'b1;

	 // 10-bit address shifted on clock negedge, send SCLK aligned with tb_clk
	 for(i = 9; i >= 0; i = i - 1)begin
	    @(negedge tb_clk)
	      SCLK = 1'b0;
	    MOSI = SPI_addr[i];
	    @(posedge tb_clk)
	      SCLK = 1'b1;
	 end

	 // 9-bit dead time for data retrieval
	 for(i = 8; i >= 0; i = i - 1)begin
	    @(negedge tb_clk)
	      SCLK = 1'b0;
	    MOSI = 1'b0;
	    @(posedge tb_clk)
	      SCLK = 1'b1;
	 end

	 // 8-bit data shifted on clock negedge, send SCLK aligned with tb_clk
	 for(i = 7; i >= 0; i = i - 1) begin
	    @(negedge tb_clk)
	      SCLK = 1'b0;
	    if(SPI_read_write == 1'b1)begin
	       MOSI =  SPI_data_in[i];
	    end else begin
	       MOSI = 1'b0;
	    end

	    @(posedge tb_clk)
	      SCLK = 1'b1;
	    //clock in data on MISO if MISO_enable = 1, else clock in that it is a high-z
	    if(MISO_enable == 1'b1)begin
	       SPI_data_out[i] = MISO;
	    end else begin
	       SPI_data_out[i] = 1'bz;
	    end
	 end // for (i = 15; i >= 0; i = i - 1)

	 // 6-bit dead time for data write
	 for(i = 5; i >= 0; i = i - 1)begin
	    @(negedge tb_clk)
	      SCLK = 1'b0;
	    MOSI = 1'b0;
	    @(posedge tb_clk)
	      SCLK = 1'b1;
	 end

	 // end message and CSN goes inactive
	 SCLK = 1'b0;
	 CSN = 1'b1;
      end
   endtask // SPI_CMD

   task baseband_CMD(
		     input [5:0] baseband_data_in
		     );

      integer			 i;

      begin
	 //shift packet
	 for(i = 5; i >= 0; i = i - 1)begin
	    @(negedge data_clk) 
	      data_in = baseband_data_in[i];
	 end
      end
   endtask // baseband_CMD

   function [7:0] compare_outputs(
				     input [7:0] expected_value,
				     input [7:0] actual_value,
				     input [9:0] address,
				     input [7:0] error_count
				     );
      if(expected_value == actual_value)begin
	 $display("PASS =  %b, Expected = %b, Actual = %b, Time = %t", address, expected_value, actual_value, $time);
	 compare_outputs = error_count;
      end else begin
	 $display("FAIL** = %b, Expected = %b, Actual = %b, Time = %t", address, expected_value, actual_value, $time);
	 compare_outputs = error_count + 1;
      end
   endfunction // compare_outputs
   
   
endmodule // modulator_64qam_top_tb

	   
	    
	 
