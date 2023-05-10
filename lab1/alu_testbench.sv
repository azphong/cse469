//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//3/29/23
//EE469 Lab1

//This module tests the ALU module against a given set of test vectors.

module alu_testbench();
	logic [103:0] testvectors [1000:0];
	logic [31:0] a, b, Result;
	logic [3:0] ALUFlags;
	logic [1:0] ALUControl;
	logic clk;
	
	alu dut (.a(a), .b(b), .ALUControl(ALUControl), .Result(Result), .ALUFlags(ALUFlags));

	parameter CLOCK_PERIOD = 100;
	
	//clock setup
	initial clk = 1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	
	initial begin
		$readmemh("alu.tv", testvectors);
	
		for(int i = 0; i < 20; i = i + 1) begin
			{ALUControl, a, b, Result, ALUFlags} = testvectors[i]; @(posedge clk);
		end //end simulation							
						
	end //initial
	
endmodule	
	