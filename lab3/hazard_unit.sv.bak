//Aaron Hong (ahong02)
//Stephen Macris (smacris)
//5/3/23
//EE469 Lab3

//This module creates an asynchronous, two read port, one write port, 16x32 register file.

//Inputs: Two 1-bits clk (clock signal), wr_en (write enable), three 4-bits write_addr, read_addr1,
//read_addr2 (write and read addresses), one 32-bit write_data (data to be written at given write address).
//Outputs: Two 32-bits read_data1, read_data2 (data read from given read addresses).
module cond_unit (cond, flags, flag_write, flags_out, cond_ex);

	input	 logic [3:0] cond, flags;
	input  logic [1:0] flag_write;
	output logic cond_ex;
	output logic [3:0] flags_out;
	
	always_comb begin
		case (cond)
			4'b0000: cond_ex = flags[2];
			4'b0001: cond_ex = !flags[2];
			4'b0010: cond_ex = flags[1];
			4'b0011: cond_ex = !flags[1];
			4'b0100: cond_ex = flags[3];
			4'b0101: cond_ex = !flags[3];
			4'b0110: cond_ex = flags[0];
			4'b0111: cond_ex = !flags[0];
			4'b1000: cond_ex = !flags[2] && flags[1];
			4'b1001: cond_ex = flags[2] || !flags[1];
			4'b1010: cond_ex = !(flags[3] ^ flags[0]);
			4'b1011: cond_ex = flags[3] ^ flags[0];
			4'b1100: cond_ex = !flags[2] && !(flags[3] ^ flags[0]);
			4'b1101: cond_ex = flags[2] || (flags[3] ^ flags[0]);
			4'b1110: cond_ex = 1;
			default: cond_ex = 0;
		endcase
		
		case (flag_write)
			2'b11: flags_out = flags;
			2'b10: flags_out = {flags[3:2], 2'b00};
			2'b01: flags_out = {2'b00, flags[1:0]};
			2'b00: flags_out = 2'b00;
			default: flags_out = 2'b00;
		endcase
	end
					
endmodule

	