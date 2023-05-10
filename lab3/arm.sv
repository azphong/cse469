/* arm is the spotlight of the show and contains the bulk of the datapath and control logic. This module is split into two parts, the datapath and control. 
*/

// clk - system clock
// rst - system reset
// Instr - incoming 32 bit instruction from imem, contains opcode, condition, addresses and or immediates
// ReadData - data read out of the dmem
// WriteData - data to be written to the dmem
// MemW - write enable to allowed WriteData to overwrite an existing dmem word
// PC - the current program count value, goes to imem to fetch instruciton
// ALUResult - result of the ALU operation, sent as address to the dmem

module arm (
    input  logic        clk, rst,
    input  logic [31:0] Instr,
    input  logic [31:0] ReadData,
    output logic [31:0] WriteData, 
    output logic [31:0] PC, ALUResult,
    output logic        MemWrite
);

    // datapath buses and signals
    logic [31:0] PCF, PCPrime, PCPlus4F, PCPlus8D; // pc signals
    logic [ 3:0] RA1D, RA2D, RA1E, RA2E;                  // regfile input addresses
    logic [31:0] RD1D, RD2D, RD1E, RD2E;                  // raw regfile outputs
    logic [ 3:0] ALUFlags, FlagsD, FlagsE;                // alu combinational flag outputs
    logic [31:0] ExtImmD, ExtImmE, SrcAE, SrcBE;        // immediate and alu inputs 
    logic [31:0] ResultW;                    // computed or fetched value to be written into regfile or pc

    // control signals
    logic PCSrcD, PCSrcE, PCSrcM, PCSrcW, PCWrPendingF;
	 logic RegWriteD, RegWriteE, RegWriteM, RegWriteW;
	 logic MemtoRegD, MemtoRegE, MemtoRegM, MemtoRegW;
	 logic MemWriteD, MemWriteE, MemWriteM;
	 logic [1:0] ALUControlD, ALUControlE;
	 logic BranchD, BranchE;
	 logic ALUSrcD, ALUSrcE;
	 logic [1:0] ImmSrcD;
	 logic Match_1E_M, Match_2E_M;
	 logic Match_1E_W, Match_2E_W;
	 logic Match_12D_E;
	 logic BranchTakenE, StallF, StallD, FlushD, FlushE, ldrStallD, CondEx, CondExE;
	 logic [1:0] FlagWriteD, FlagWriteE, RegSrcD; 
	 logic [1:0] ForwardAE, ForwardBE;
	 logic [3:0] CondE, WA3E, WA3M, WA3W;
	 logic [31:0] ALUOutW, ALUOutM;
	 logic [31:0] InstrF, InstrD;
	 logic [31:0] ReadDataM, ReadDataW;
	 logic [31:0] WriteDataE, WriteDataM;
	 logic [31:0] ALUResultE;

	 
    /* The datapath consists of a PC as well as a series of muxes to make decisions about which data words to pass forward and operate on. It is 
    ** noticeably missing the register file and alu, which you will fill in using the modules made in lab 1. To correctly match up signals to the 
    ** ports of the register file and alu take some time to study and understand the logic and flow of the datapath.
    */
    //-------------------------------------------------------------------------------
    //                                      DATAPATH
    //-------------------------------------------------------------------------------

	 // connect module inputs and outputs to datapath
	 assign InstrF = Instr;
	 assign ReadDataM = ReadData;
	 assign WriteData = WriteDataM;
	 assign MemWrite = MemWriteM;
	 assign PC = PCF;
	 assign ALUResult = ALUOutM;
	 
    assign PCPrime = BranchTakenE ? ALUResultE : (PCSrcW ? ResultW : PCPlus4F);  // mux, use either default or newly computed value
	 assign PCPlus4F = PCF + 'd4;                  // default value to access next instruction
    assign PCPlus8D = PCPlus4F;             // value read when reading from reg[15]

    // update the PC, at rst initialize to 0
    always_ff @(posedge clk) begin
        if (rst)          PCF <= '0; 
        else if (!StallF) PCF <= PCPrime;
		  else              PCF <= PCF;
    end

    // determine the register addresses based on control signals
    // RegSrcD[0] is set if doing a branch instruction
    // RefSrc[1] is set when doing memory instructions
    assign RA1D = RegSrcD[0] ? 4'd15         : InstrD[19:16];
    assign RA2D = RegSrcD[1] ? InstrD[15:12] : InstrD[ 3: 0];

    // Instantiates a register file to hold values.
    reg_file u_reg_file (
        .clk       (!clk), 
        .wr_en     (RegWriteW),
        .write_data(ResultW),
        .write_addr(WA3W),
        .read_addr1(RA1D), 
        .read_addr2(RA2D),
        .read_data1(RD1D), 
        .read_data2(RD2D)
    );

    // two muxes, put together into an always_comb for clarity
    // determines which set of instruction bits are used for the immediate
    always_comb begin
        if      (ImmSrcD == 'b00) ExtImmD = {{24{InstrD[7]}},InstrD[7:0]};          // 8 bit immediate - reg operations
        else if (ImmSrcD == 'b01) ExtImmD = {20'b0, InstrD[11:0]};                 // 12 bit immediate - mem operations
        else                      ExtImmD = {{6{InstrD[23]}}, InstrD[23:0], 2'b00}; // 24 bit immediate - branch operation
    end

    // WriteData and SrcA are direct outputs of the register file, wheras SrcB is chosen between reg file output and the immediate            
    assign SrcBE = ALUSrcE ? ExtImmE : WriteDataE;     // determine alu operand to be either from reg file or from immediate
	 // Depending on forwarding control signal from hazard unit, choose appropriate ALU operand
	 always_comb begin
		case (ForwardAE)
			2'b00: SrcAE = (RA1E == 'd15) ? (BranchTakenE ? PCPlus8D : PCF) : RD1E; // substitute the 15th regfile register for PC
			2'b01: SrcAE = ResultW;
			2'b10: SrcAE = ALUOutM;
			default: SrcAE = RD1E;
		endcase
		
		case (ForwardBE)
			2'b00: WriteDataE = (RA2E == 'd15) ? (BranchTakenE ? PCPlus8D : PCF) : RD2E; // substitute the 15th regfile register for PC
			2'b01: WriteDataE = ResultW;
			2'b10: WriteDataE = ALUOutM;
			default: WriteDataE = RD2E;
		endcase
	 end
			

    // Instantiates an alu module to do arithmetic operations.
    alu u_alu (
        .a          (SrcAE), 
        .b          (SrcBE),
        .ALUControl (ALUControlE),
        .Result     (ALUResultE),
        .ALUFlags   (ALUFlags)
    );

    // determine the result to run back to PC or the register file based on whether we used a memory instruction
    assign ResultW = MemtoRegW ? ReadDataW : ALUOutW;    // determine whether final writeback result is from dmemory or alu

	 // input signals for the hazard unit
	 assign Match_1E_M = (RA1E == WA3M);
	 assign Match_2E_M = (RA2E == WA3M);
	 assign Match_1E_W = (RA1E == WA3W);
	 assign Match_2E_W = (RA2E == WA3W);
	 assign Match_12D_E = ((RA1D == WA3E) + (RA2D == WA3E));
	 assign PCWrPendingF = (PCSrcD + PCSrcE + PCSrcM) & !BranchTakenE;
	 assign BranchTakenE = BranchE & CondExE;
	 
	 // Instantiate a conditional unit to manage flags register and determine instruction execution
	 cond_unit u_cond_unit (
			.cond			(CondE),
			.flags		(FlagsE),
			.ALUFlags   (ALUFlags),
			.flag_write (FlagWriteE),
			.flags_out  (FlagsD),
			.cond_ex		(CondExE)
	 );
	 
	 // Instantiate a hazard unit to provide stalling, flushing, and forwarding control signals
	 hazard_unit u_hazard_unit (
			.Match_1E_M	(Match_1E_M),
			.Match_2E_M (Match_2E_M),
			.Match_1E_W (Match_1E_W),
			.Match_2E_W (Match_2E_W),
			.Match_12D_E(Match_12D_E),
			.RegWriteM  (RegWriteM),
			.RegWriteW  (RegWriteW),
			.MemtoRegE  (MemtoRegE),
			.BranchTakenE (BranchTakenE),
			.PCWrPendingF (PCWrPendingF),
			.PCSrcW (PCSrcW),
			.ForwardAE	(ForwardAE),
			.ForwardBE	(ForwardBE),
			.StallF (StallF),
			.StallD (StallD),
			.FlushD (FlushD),
			.FlushE (FlushE)
	 );
	 
	 // Synchronously move signals along the datapath
	 always_ff @(posedge clk) begin
			//Fetch to Decode
			if (FlushD) InstrD <= 32'b0;
			else if (!rst && !StallD) InstrD <= InstrF;

			//Decode to Execute
			if (!FlushE) begin
				PCSrcE <= PCSrcD;
				RegWriteE <= RegWriteD;
				MemtoRegE <= MemtoRegD;
				MemWriteE <= MemWriteD;
				ALUControlE <= ALUControlD;
				BranchE <= BranchD;
				ALUSrcE <= ALUSrcD;
				FlagWriteE <= FlagWriteD;
				CondE <= InstrD[31:28];
				FlagsE <= FlagsD;
				RD1E <= RD1D;
				RD2E <= RD2D;
				RA1E <= RA1D;
				RA2E <= RA2D;
				WA3E <= InstrD[15:12];
				ExtImmE <= ExtImmD;
			end else begin
				PCSrcE <= 0;
				RegWriteE <= 0;
				MemtoRegE <= 0;
				MemWriteE <= 0;
				ALUControlE <= 0;
				BranchE <= 0;
				ALUSrcE <= 0;
				FlagWriteE <= 0;
				CondE <= 4'b1111;
				FlagsE <= 0;
				RD1E <= 0;
				RD2E <= 0;
				WA3E <= 0;
				ExtImmE <= 0;
			end
			
			//Execute to Memory
			if (!BranchTakenE) begin
				PCSrcM <= PCSrcE & CondExE;
				RegWriteM <= RegWriteE & CondExE;
				MemtoRegM <= MemtoRegE;
				MemWriteM <= MemWriteE & CondExE;
				WriteDataM <= WriteDataE;
				ALUOutM <= ALUResultE;
				WA3M <= WA3E;
			end
			
			//Memory to Writeback
			ReadDataW <= ReadDataM;
			ALUOutW <= ALUOutM;
			WA3W <= WA3M;
			PCSrcW <= PCSrcM;
			RegWriteW <= RegWriteM;
			MemtoRegW <= MemtoRegM;	
	 end
	 
	
    /* The control conists of a large decoder, which evaluates the top bits of the instruction and produces the control bits 
    ** which become the select bits and write enables of the system. The write enables (RegW, MemW and PCS) are 
    ** especially important because they are representative of your processors current state. 
    */
    //-------------------------------------------------------------------------------
    //                                      CONTROL
    //-------------------------------------------------------------------------------
    always_comb begin
        casez (InstrD[27:20])

            // ADD (Imm or Reg)
            8'b00?_0100_? : begin   // note that we use wildcard "?" in bit 25. That bit decides whether we use immediate or reg, but regardless we add
                PCSrcD    = 0;
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = InstrD[25]; // may use immediate
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00; 
                ALUControlD = 'b00;
					 FlagWriteD = {InstrD[20], InstrD[20]};
					 BranchD = 0;
            end

            // SUB/CMP (Imm or Reg)
            8'b00?_0010_? : begin   // note that we use wildcard "?" in bit 25. That bit decides whether we use immediate or reg, but regardless we sub
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = InstrD[25]; // may use immediate
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00; 
                ALUControlD = 'b01;
					 FlagWriteD = {InstrD[20], InstrD[20]};
					 BranchD = 0;
            end

            // AND
            8'b000_0000_? : begin
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = 0; 
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00;    // doesn't matter
                ALUControlD = 'b10; 
					 FlagWriteD = {InstrD[20], 1'b0};
					 BranchD = 0;
					 //FlagWriteE = 00; 
            end

            // ORR
            8'b000_1100_? : begin
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = 0; 
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00;    // doesn't matter
                ALUControlD = 'b11;
					 FlagWriteD = {InstrD[20], 1'b0};
					 BranchD = 0;
            end

            // LDR
            8'b010_1100_1 : begin
                PCSrcD    = 0; 
                MemtoRegD = 1; 
                MemWriteD = 0; 
                ALUSrcD   = 1;
                RegWriteD = 1;
                RegSrcD   = 'b10;    // msb doesn't matter
                ImmSrcD   = 'b01; 
                ALUControlD = 'b00;  // do an add
					 FlagWriteD = 00;
					 BranchD = 0;
            end

            // STR
            8'b010_1100_0 : begin
					 PCSrcD    = 0; 
					 MemtoRegD = 0; // doesn't matter
					 MemWriteD = 1; 
					 ALUSrcD   = 1;
					 RegWriteD = 0;
					 RegSrcD   = 'b10;    // msb doesn't matter
					 ImmSrcD   = 'b01; 
					 ALUControlD = 'b00;  // do an add
					 FlagWriteD = 00;
					 BranchD = 0;
            end

            // B
            8'b1010_???? : begin
					if(CondExE) begin
						 PCSrcD    = 1; 
						 MemtoRegD = 0;
						 MemWriteD = 0; 
						 ALUSrcD   = 1;
						 RegWriteD = 0;
						 RegSrcD   = 'b01;
						 ImmSrcD   = 'b10; 
						 ALUControlD = 'b00;  // do an add
						 FlagWriteD = 00;
						 BranchD = 1;
					 end else begin
						 PCSrcD    = 0; 
						 MemtoRegD = 0; 
						 MemWriteD = 0; 
						 ALUSrcD   = 0; 
						 RegWriteD = 0;
						 RegSrcD   = 'b00;
						 ImmSrcD   = 'b00;    // doesn't matter
						 ALUControlD = 'b00;
						 FlagWriteD = 00;
						 BranchD = 0;
					 end
            end
				
//            // CMP
//            8'b00?00101 : begin
//					  PCS    = 0; 
//					  MemtoRegD = 0;
//					  MemW = 0; 
//					  ALUSrcD   = Instr[25];
//					  RegW = 1;
//					  RegSrcD   = 'b00;
//					  ImmSrcD   = 'b00; 
//					  ALUControlD = 'b01;  // subtract
//					  FlagWriteE = 11;
//            end
				
			default: begin
					  PCSrcD    = 0; 
					  MemtoRegD = 0; // doesn't matter
					  MemWriteD = 0; 
					  ALUSrcD   = 0;
					  RegWriteD = 0;
					  RegSrcD   = 'b00;
					  ImmSrcD   = 'b00; 
					  ALUControlD = 'b00;  // do an add
					  FlagWriteD = 00;
					  BranchD = 0;
			end
        endcase
    end


endmodule