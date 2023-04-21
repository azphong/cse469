//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//3/29/23
//EE469 Lab1

//This module creates a basic arithmetic logic unit capable of addition, subtraction,
//ANDing, and ORing.

//Inputs: Two 32-bits a, b (inputs to be processed), one 2-bit ALUControl (controls which operation).
//Outputs: One 32-bit Result (result of chosen operation), one 4-bit ALUFlags (flags thrown depending on the result).
module alu (a, b, ALUControl, Result, ALUFlags);

	input  logic  [31:0] a, b;
	input  logic [1:0] ALUControl;
	output logic [31:0] Result;
	output logic [3:0] ALUFlags;
	logic cout, x, diff_sign;
	logic [31:0] sum, b_mod;
	
	assign x = ~ALUControl[0] & ~ALUControl[1] & (a[31] == b[31]);
	assign diff_sign = a[31] ^ sum[31];
	
	//Instantiates a 32-bit full adder to do addition and subtraction operations.
	fulladder32 FA(.A(a), .B(b_mod), .cin(ALUControl[0]), .sum(sum), .cout(cout));

	//Determines what operation to perform depending on ALUControl.
   always_comb begin
		case (ALUControl[0])
			1'b0: b_mod = b;
			1'b1: b_mod = ~b;
		endcase;
		
		case (ALUControl)
			2'b00: Result = sum; 
         2'b01: Result = sum; 
			2'b10: Result = a & b;
			2'b11: Result = a | b;
      endcase

      ALUFlags[3] = Result[31];
      ALUFlags[2] = (Result == 32'b0);
		ALUFlags[1] = ~ALUControl[1] & cout;
      ALUFlags[0] = x & diff_sign & ~ALUControl[1];
	end
					
endmodule