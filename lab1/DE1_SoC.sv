//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//11/18/22
//EE271 Lab4

//Instantiates meta, userinput, normallight, centerlight, and victory modules onto an FPGA board
//and simulates a game of tug-of-war. Using KEY[3] and KEY[0], two players try to "pull" the lit
//LED across LEDR[9] to LEDR[1]. The winning side is displayed on the HEX display when one player
//succeeds in pulling the LED to their end of the playing field. The game resets with SW[9].

//Simulates a game of tug-of-war using LEDR[9:1] as the playing field, KEY[3] and KEY[0] as 
//tugs from the players, and SW[9] to reset the game. Should one player win, the winning side
//is displayed on the HEX display.
//Inputs: One 10-bit input SW, one 4-bit input KEY, one 1-bit input (clock signal) CLOCK-50
//Outputs: One 10-bit output LEDR, six 7-bit outputs HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
module DE1_SoC (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW);
	
	input logic CLOCK_50; // 50MHz clock
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input logic [3:0] KEY; // Active low property
	input logic [9:0] SW;
	logic rawL, rawR, L, R, simR, countL, countR, roundOver, gameOverL, gameOverR, gameOver, divclk; 
	logic [9:0] random;
	logic [31:0] divided_clock;
	logic [2:0] scoreL, scoreR;

	logic reset;  // configure reset

	assign reset = SW[9]; // Reset when SW[9] is pressed
	
	clock_divider cdiv (.clock(CLOCK_50), .divided_clocks(divided_clock));
	assign divclk = CLOCK_50;
	
	//Instantiates meta module twice, one for the left and one for the right, respectively using KEY[3] 
	//and KEY[0] as inputs. The synchronised outputs are stored in intermediate logic. divclk is used 
	//as the clock signal and the reset input is connected to SW[9].
	//Note: for use on an actual FPGA board, KEY[3] and KEY[0] must be inverted with a ~ as they are 
	//active low. For simulation purposes, the inversion is not required.
	meta ml (.clk(divclk), .reset(reset), .d(KEY[3]), .q(rawL));
	meta mr (.clk(divclk), .reset(reset), .d(simR), .q(rawR));
	
	//Instantiates two userinput modules, one for each player. The intermediate logics from the meta modules
	//are used as the raw inputs and the processed outputs are passed into more intermediate logics. divclk 
	//is used as the clock signal and the reset input is connected to SW[9].
	userinput ul (.clk(divclk), .reset(reset), .raw(rawL), .out(L));
	userinput ur (.clk(divclk), .reset(reset), .raw(rawR), .out(R));
	lfsr l (.clk(divclk), .reset(reset), .out(random));
	comparator cyberComp (.clk(divclk), .reset(reset), .A({1'b0, SW[8:0]}), .B(random), .out(simR));
	comparator roundComp (.clk(divclk), .reset(reset), .A({8'b00000000, countL, countR}), .B(10'b0000000000), .out(roundOver));
	comparator lComp (.clk(divclk), .reset(reset), .A({7'b0000000, scoreL}), .B(10'b0000000110), .out(gameOverL));
	comparator rComp (.clk(divclk), .reset(reset), .A({7'b0000000, scoreR}), .B(10'b0000000110), .out(gameOverR));
	comparator gameComp (.clk(divclk), .reset(reset), .A({8'b00000000, gameOverL, gameOverR}), .B(10'b0000000000), .out(gameOver));
	
	//assign LEDR[0] = divclk;
	
	//Instantiates 8 normallight modules and 1 centerlight module, each controlling the lit status of one LED within LEDR[9:1]. 
	//Every module takes the outputs from the userinput modules as inputs for the players. Each instantiation
	//also receives the lit status of its adjacent LEDs as inputs. The normallight modules also take an additional input
	//from intermediate logic which determines whether the game has ended. divclk is used as the clock signal and the reset
	//input is connected to SW[9].
	normallight led9 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(1'b0), .NR(LEDR[8]), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[9]));
	normallight led8 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[9]), .NR(LEDR[7]), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[8]));
	normallight led7 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[8]), .NR(LEDR[6]), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[7]));
	normallight led6 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[7]), .NR(LEDR[5]), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[6]));
	centerlight led5 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[6]), .NR(LEDR[4]), .roundOver(roundOver), .on(LEDR[5]));
	normallight led4 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[5]), .NR(LEDR[3]), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[4]));
	normallight led3 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[4]), .NR(LEDR[2]), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[3]));
	normallight led2 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[3]), .NR(LEDR[1]), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[2]));
	normallight led1 (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[2]), .NR(1'b0), .roundOver(roundOver), .gameOver(gameOver), .on(LEDR[1]));
	
	//Instantiates the victory module, taking the outputs from the userinput module as player inputs. The adjacent light inputs
	//are taken from the LEDs at the ends of the playing field, as to detect when the lit LED is "pulled" off of the field. HEX display
	//codes are outputted to HEX5, HEX4, HEX3, HEX2, HEX1, and HEX0 and logic that stores when the game is over is outputted into
	//intermediate logic for the normallight modules to use. divclk is used as the clock signal and the reset input is connected to SW[9].
	victory v (.clk(divclk), .reset(reset), .L(L), .R(R), .NL(LEDR[1]), .NR(LEDR[9]), .win({countL, countR}));
	counter cl (.clk(divclk), .reset(reset), .incr(countL), .out(scoreL));
	counter cr (.clk(divclk), .reset(reset), .incr(countR), .out(scoreR));
	seg7 sl (.bcd(scoreL), .leds(HEX1));
	seg7 sr (.bcd(scoreR), .leds(HEX0));

endmodule

//Tests DE1_SoC by creating a clock signal and simulating player inputs to a game of tug-of-war.
module DE1_SoC_testbench ();

	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR;
	logic [3:0] KEY;
	logic [9:0] SW;
	logic CLOCK_50;
	
	DE1_SoC dut (.CLOCK_50, .HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5, .KEY, .LEDR, .SW);
	
	parameter clock_period = 100;
	
	initial begin
		CLOCK_50 <= 0;
		forever #(clock_period /2) CLOCK_50 <= ~CLOCK_50;
				
	end //initial
	
	initial begin
	
			SW[9] <= 1; @(posedge CLOCK_50);
			SW[9] <= 0; @(posedge CLOCK_50);
		 KEY[0]<=0; KEY[3]<=0;   @(posedge CLOCK_50);
		 SW[8:0] <= 100000000; KEY[0]<=0; KEY[3]<=0;   @(posedge CLOCK_50);
							KEY[0]<=1; KEY[3]<=0;  	@(posedge CLOCK_50);
							KEY[0]<=0;		   		@(posedge CLOCK_50);
			            KEY[3]<=1;        		@(posedge CLOCK_50);	
			            KEY[3]<=0;       			@(posedge CLOCK_50);	
							KEY[3]<=1;					@(posedge CLOCK_50);	
															@(posedge CLOCK_50);	
															@(posedge CLOCK_50);	
							KEY[3]<=0;		  			@(posedge CLOCK_50);	
							KEY[3]<=1;        		@(posedge CLOCK_50);	
			            KEY[3]<=0;       			@(posedge CLOCK_50);	
							KEY[3]<=1;        		@(posedge CLOCK_50);
															@(posedge CLOCK_50);
			            KEY[3]<=0;        		@(posedge CLOCK_50);	
							KEY[3]<=1;        		@(posedge CLOCK_50);	
			            KEY[3]<=0;        		@(posedge CLOCK_50);	
							KEY[3]<=1;        		@(posedge CLOCK_50);	
			            KEY[3]<=0;        		@(posedge CLOCK_50);	
							KEY[3]<=1;        		@(posedge CLOCK_50);	
			            KEY[3]<=0;        		@(posedge CLOCK_50);	
							KEY[3]<=1;        		@(posedge CLOCK_50);	
			            KEY[3]<=0;        		@(posedge CLOCK_50);	
															@(posedge CLOCK_50);
			for(int i = 0; i < 100; i++) begin
				@(posedge CLOCK_50);
			end
			
		$stop; //end simulation							
						
	end //initial

endmodule
