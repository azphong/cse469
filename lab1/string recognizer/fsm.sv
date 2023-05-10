
//module to implement a string recognizer for the string 101

module fsm (clk, reset, w, out);

	input  logic  clk, reset, w;
	output logic  out;

	enum {S0, S1, S2} ps, ns; // Present state, next state

	//Next state logic
	always_comb begin
		case (ps)
			S0: if (w) ns = S1;
					else ns = S0;
			S1: if (w) ns = S1;
					else ns = S2;
			S2: if (w) ns = S1;
					else ns = S0;
		endcase
	end
			
	assign out = (ps == S2) & w;  //use this statement or the next one
	//assign out = ps[1] & w;
	
	//sequential logic (DFFs)
		always_ff @(posedge clk) begin
			if (reset)
				ps <= S0;
			else
				ps <= ns;
		end
				
	
endmodule



module fsm_testbench();

		logic clk, reset, w, out;
		
		fsm dut (.clk, .reset, .w, .out);
		
		//clock setup
		parameter clock_period = 100;
		
		initial begin
			clk <= 0;
			forever #(clock_period /2) clk <= ~clk;
					
		end //initial
		
		initial begin
		
			reset <= 1;         @(posedge clk);
			reset <= 0; w<=0;   @(posedge clk);
									  @(posedge clk);
			                    @(posedge clk);	
			                    @(posedge clk);	
			            w<=1;   @(posedge clk);	
							w<=0;   @(posedge clk);	
							w<=1;   @(posedge clk);	
									  @(posedge clk);	
			                    @(posedge clk);	
			                    @(posedge clk);	
							w<=0;   @(posedge clk);	
									  @(posedge clk);	
									  @(posedge clk);	
									  @(posedge clk);
							w<=1;   @(posedge clk);	
							w<=0;   @(posedge clk);	
							w<=1;   @(posedge clk);	
									  @(posedge clk);
									  @(posedge clk);
			$stop; //end simulation							
							
		end //initial
		
endmodule		