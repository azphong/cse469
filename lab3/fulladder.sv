//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//EE469 Lab1

//Adds two 1-bit values and a carry-in value.

//Inputs: Three 1-bits A, B (inputs to be added), cin (carry-in value).
//Outputs: Two 1-bits sum (sum), cout (carry-out value).
module fulladder (A, B, cin, sum, cout);

	input logic A, B, cin;
	output logic sum, cout;
	
	assign sum = A ^ B ^ cin;
	assign cout = A&B | cin & (A^B);
	
endmodule

//Tests module fulladder by simulating all 2^3 input bit combinations
module fulladder_testbench();

	logic A, B, cin, sum, cout;
	
	fulladder dut (A, B, cin, sum, cout);
	
	
	integer i;
	initial begin
	
		for(i=0; i<2**3; i++) begin
		 {A, B, cin} = i; #10;
		end //for loop
	
	end //initial
	
endmodule
