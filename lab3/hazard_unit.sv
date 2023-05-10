//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//5/3/23
//EE469 Lab3

//This module creates an asynchronous hazard unit that outputs stalling, flushing, and forwarding control signals.

module hazard_unit (
	input logic Match_1E_M, Match_2E_M,
	input logic Match_1E_W, Match_2E_W,
	input logic Match_12D_E,
	input logic RegWriteM, RegWriteW, MemtoRegE, BranchTakenE, PCWrPendingF, PCSrcW,
	output logic [1:0] ForwardAE, ForwardBE, 
	output logic StallF, StallD, FlushD, FlushE
	);
	
	logic ldrStallD;
	
	assign ldrStallD = Match_12D_E & MemtoRegE;
	
	assign StallF = ldrStallD + PCWrPendingF;
	assign FlushD = PCWrPendingF + PCSrcW + BranchTakenE;
	assign FlushE = ldrStallD + BranchTakenE;
	assign StallD = ldrStallD;
	
	always_comb begin
		if 	  (Match_1E_M && RegWriteM) ForwardAE = 2'b10;
		else if (Match_1E_W && RegWriteW) ForwardAE = 2'b01;
		else 										 ForwardAE = 2'b00;
		
		if 	  (Match_2E_M && RegWriteM) ForwardBE = 2'b10;
		else if (Match_2E_W && RegWriteW) ForwardBE = 2'b01;
		else 										 ForwardBE = 2'b00;
	end
					
endmodule

	