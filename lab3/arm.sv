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
    input  logic [31:0] InstrF,
    input  logic [31:0] ReadDataM,
    output logic [31:0] WriteDataM, 
    output logic [31:0] PCF, ALUOutM,
    output logic        MemWriteM
);

    // datapath buses and signals
    logic [31:0] PCPrime, PCPlus4F, PCPlus8D; // pc signals
    logic [ 3:0] RA1D, RA2D;                  // regfile input addresses
    logic [31:0] RD1D, RD2D, RD1E, RD2E;                  // raw regfile outputs
    logic [ 3:0] ALUFlags, FlagsD, FlagsE;                  // alu combinational flag outputs
    logic [31:0] ExtImmD, ExtImmE, SrcAE, SrcBE;        // immediate and alu inputs 
    logic [31:0] ResultW;                    // computed or fetched value to be written into regfile or pc

    // control signals
    logic PCSrcD, PCSrcE, PCSrcM, PCSrcW;
	 logic RegWriteD, RegWriteE, RegWriteM, RegWriteW;
	 logic MemtoRegD, MemtoRegE, MemtoRegM, MemtoRegW;
	 logic MemWriteD, MemWriteE;
	 logic ALUControlD, ALUControlE;
	 logic BranchD, BranchE;
	 logic ALUSrcD, ALUSrcE;
	 logic ImmSrcD;
	 logic [1:0] FlagWriteD, FlagWriteE, RegSrcD; 
	 logic [3:0] CondE, WA3E, WA3M;
	 
	 logic [31:0] InstrD, ALUResultE, WriteDataE, ReadDataW, ALUOutW;


    /* The datapath consists of a PC as well as a series of muxes to make decisions about which data words to pass forward and operate on. It is 
    ** noticeably missing the register file and alu, which you will fill in using the modules made in lab 1. To correctly match up signals to the 
    ** ports of the register file and alu take some time to study and understand the logic and flow of the datapath.
    */
    //-------------------------------------------------------------------------------
    //                                      DATAPATH
    //-------------------------------------------------------------------------------


    assign PCPrime = BranchTakenE ? (PCSrcW ? ResultW : PCPlus4F) : ALUResultE;  // mux, use either default or newly computed value
	 assign PCPlus4F = PCF + 'd4;                  // default value to access next instruction
    assign PCPlus8D = PCPlus4F;             // value read when reading from reg[15]

    // update the PC, at rst initialize to 0
    always_ff @(posedge clk) begin
        if (rst) PCF <= '0;
        else     PCF <= PCPrime;
    end

    // determine the register addresses based on control signals
    // RegSrcD[0] is set if doing a branch instruction
    // RefSrc[1] is set when doing memory instructions
    assign RA1D = RegSrcD[0] ? 4'd15         : InstrD[19:16];
    assign RA2D = RegSrcD[1] ? InstrD[15:12] : InstrD[ 3: 0];

    // Instantiates a register file to hold values.
    reg_file u_reg_file (
        .clk       (clk), 
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
    assign WriteDataE = (RA2D == 'd15) ? PCPlus8D : RD2E;           // substitute the 15th regfile register for PC 
    assign SrcAE      = (RA1D == 'd15) ? PCPlus8D : RD1E;           // substitute the 15th regfile register for PC 
    assign SrcBE      = ALUSrcD        ? ExtImmE  : WriteDataE;     // determine alu operand to be either from reg file or from immediate


    // Instantiates an alu module to do arithmetic operations.
    alu u_alu (
        .a          (SrcAE), 
        .b          (SrcBE),
        .ALUControl (ALUControlE),
        .Result     (ALUResultE),
        .ALUFlags   (ALUFlags)
    );

    // determine the result to run back to PC or the register file based on whether we used a memory instruction
    assign ResultW = MemtoRegD ? ReadDataW : ALUOutW;    // determine whether final writeback result is from dmemory or alu

	 
    /* The control conists of a large decoder, which evaluates the top bits of the instruction and produces the control bits 
    ** which become the select bits and write enables of the system. The write enables (RegW, MemW and PCS) are 
    ** especially important because they are representative of your processors current state. 
    */
    //-------------------------------------------------------------------------------
    //                                      CONTROL
    //-------------------------------------------------------------------------------
    
	 assign BranchTakenE = BranchE & CondExE;
	 
	 always_ff @(posedge clk) begin
			//Fetch to Decode
			InstrD = InstrF;
			
			//Decode to Execute
			PCSrcE = PCSrcD;
			RegWriteE = RegWriteD;
			MemtoRegE = MemtoRegD;
			MemWriteE = MemWriteD;
			ALUControlE = ALUControlD;
			BranchE = BranchD;
			ALUSrcE = ALUSrcD;
			FlagWriteE = FlagWriteD;
			CondE = InstrD[31:28];
			FlagsE = FlagsD;
			RD1E = RD1D;
			RD2E = RD2D;
			WA3E = InstrD[15:12];
			ExtImmE = ExtImmD;
			
			//Execute to Memory
			PCSrcM = (PCSrcE | BranchE) & CondExE;
			RegWriteM = RegWriteE & CondExE;
			MemtoRegM = MemtoRegE;
			MemWriteM = MemWriteE & CondExE;
			WriteDataM = WriteDataE;
			ALUOutM = ALUResultE;
			WA3M = WA3E;
			
			//Memory to Writeback
			ReadDataW = ReadDataM;
			ALUOutW = ALUOutM;
			WA3W = WA3M;
			PCSrcW = PCSrcM;
			RegWriteW = RegWriteM;
			MemtoRegW = MemtoRegM;	
	 end
	 
	 cond_unit u_cond_unit (
			.cond			(InstrD[31:28]),
			.flags		(ALUFlags),
			.flag_write (FlagWriteE),
			.flags_out  (FlagsD),
			.cond_ex		(CondExE)
	 );
	 
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