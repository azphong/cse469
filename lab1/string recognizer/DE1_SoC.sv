
module DE1_SoC (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW);
	
	input logic CLOCK_50; // 50MHz clock
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input logic [3:0] KEY; // Active low property
	input logic [9:0] SW;

	// Generate clk off of CLOCK_50, whichClock picks rate.

	logic [31:0] clk;

	parameter whichClock = 25;

	clock_divider cdiv (CLOCK_50, clk);

	logic reset;  // configure reset

	assign reset = ~KEY[0]; // Reset when KEY[0] is pressed
	
	assign LEDR[5] = clk[whichClock];
	
	// instantiates Hazard light and assigned corresponding ports
	fsm f1 (.clk(clk[whichClock]), .reset(reset), .w(SW[0]), .out(LEDR[0]));

endmodule

	// divided_clocks[0] = 25MHz, [1] = 12.5Mhz, ... [23] = 3Hz, [24] = 1.5Hz, [25] = 0.75Hz, ...

module clock_divider (clock, divided_clocks);
	input logic clock;
	output logic [31:0] divided_clocks;

	initial begin
		divided_clocks <= 0;
	end

	always_ff @(posedge clock) begin
		divided_clocks <= divided_clocks + 1;
   end

endmodule