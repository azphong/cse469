//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//3/29/23
//EE469 Lab1

//This testbench tests reg_file to ensure that it functions properly: mostly testing asynchronous read.

module reg_file_testbench();

		logic clk, wr_en;
		logic [31:0] write_data, read_data1, read_data2;
		logic [3:0] write_addr, read_addr1, read_addr2;
		
		reg_file dut (.clk(clk), .wr_en(wr_en), .write_data(write_data), .write_addr(write_addr), .read_addr1(read_addr1), .read_addr2(read_addr2), .read_data1(read_data1), .read_data2(read_data2));
	
		//clock setup
		parameter clock_period = 100;
		initial begin
			clk <= 0;
			forever #(clock_period /2) clk <= ~clk;
					
		end //initial
		
		initial begin
		
			wr_en <= 1'b0;	write_addr <= 4'b0010; write_data <= 32'd8; read_addr1 <= 4'b0000; read_addr2 <= 4'b0001;  @(posedge clk);
			wr_en <= 1'b1; 																														 @(posedge clk);
			wr_en <= 1'b0;	write_addr <= 4'b0100; write_data <= 32'd16; read_addr1 <= 4'b0000; read_addr2 <= 4'b0001; @(posedge clk);
			wr_en <= 1'b1; 																														 @(posedge clk);
																																						 @(posedge clk);
			wr_en <= 1'b0; read_addr1 <= 4'b0010; 																							 @(posedge clk);
			wr_en <= 1'b0; read_addr2 <= 4'b0100; 																							 @(posedge clk);
			wr_en <= 1'b1; write_addr <= 4'b0011; write_data <= 32'd32; read_addr2 <= 4'b0011; 								 @(posedge clk);
																																						 @(posedge clk);
			wr_en <= 1'b0; 																														 @(posedge clk);
			wr_en <= 1'b1; write_addr <= 4'b0111; write_data <= 32'd64; read_addr1 <= 4'b0111; 								 @(posedge clk);
																																						 @(posedge clk);
																																						 @(posedge clk);
																																						 @(posedge clk);
			
			$stop; //end simulation							
							
		end //initial
		
endmodule	
	