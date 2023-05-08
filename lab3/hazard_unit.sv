//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//5/3/23
//EE469 Lab3

//This module creates an asynchronous, two read port, one write port, 16x32 register file.

//Inputs: Two 1-bits clk (clock signal), wr_en (write enable), three 4-bits write_addr, read_addr1,
//read_addr2 (write and read addresses), one 32-bit write_data (data to be written at given write address).
//Outputs: Two 32-bits read_data1, read_data2 (data read from given read addresses).
module hazard_unit (
	input logic Match_1E_M, Match_2E_M,
	input logic Match_1E_W, Match_2E_W,
	input logic Match_12D_E,
	input logic RegWriteM, RegWriteW, MemtoRegE,
	output logic [1:0] ForwardAE, ForwardBE, 
	output logic ldrStallD
	);
	
	
	
	assign ldrstallD = Match_12D_E && MemtoRegE;
	
	
	always_comb begin
		if 	  (Match_1E_M && RegWriteM) ForwardAE = 10;
		else if (Match_1E_W && RegWriteW) ForwardAE = 01;
		else 										 ForwardAE = 00;
		
		if 	  (Match_2E_M && RegWriteM) ForwardBE = 10;
		else if (Match_2E_W && RegWriteW) ForwardBE = 01;
		else 										 ForwardBE = 00;
	end
					
endmodule

	