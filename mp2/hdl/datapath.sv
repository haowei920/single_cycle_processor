

`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input clk,
    input rst,
/********************control to datapath signals******************************/
    input load_mdr,
	 input load_mar,
	 input load_data_out,
	 input load_ir,
	 input load_regfile,
	 input load_pc,
	 input pcmux::pcmux_sel_t pcmux_sel,
	 input alumux::alumux1_sel_t alumux1_sel,
	 input alumux::alumux2_sel_t alumux2_sel,
	 input marmux::marmux_sel_t marmux_sel,
	 input cmpmux::cmpmux_sel_t cmpmux_sel,
	 input regfilemux::regfilemux_sel_t regfilemux_sel,
	 input alu_ops aluop,
	 input branch_funct3_t cmpop,
	 input [3:0] rmask_for_datapath,
/*****************************************************************************/

/********************memory to datapath signals******************************/
    input rv32i_word mem_rdata,
/*****************************************************************************/

/********************datapath to memory signals******************************/
	 output rv32i_word mem_address,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
	 
/*****************************************************************************/

    /* You will need to connect more signals to your datapath module*/
/********************datapath to control signals******************************/
	 output rv32i_opcode opcode,
	 output logic [2:0] funct3,
	 output logic [6:0] funct7,
	 output logic br_en,
	 output logic [4:0] rs1,
	 output logic [4:0] rs2,
	 output rv32i_word mem_address_to_datapath
/*****************************************************************************/
);




/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
/*****************************************************************************/
rv32i_word temp_mem_wdata;
rv32i_word regfilemux_out;
rv32i_word pc_out;
rv32i_word pc_plus4_out;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word MAR_out;
rv32i_word MARmux_out;
rv32i_word alu_out;
rv32i_word cmpmux_out;
rv32i_word my_i_imm;
rv32i_word my_s_imm;
rv32i_word my_b_imm;
rv32i_word my_u_imm;
rv32i_word my_j_imm; //extra
rv32i_word alumux1_out;
rv32i_word alumux2_out;
//rv32i_word mem_address_to_datapath;
assign mem_address = {MAR_out[31:2],2'b0};
//assign mem_address = MAR_out;
assign mem_address_to_datapath = MAR_out;
logic [2:0] control_bits_for_mem_address;
assign control_bits_for_mem_address = MAR_out[1:0];
///******************* Extra Stuff *************************/
logic [4:0] rd;
///*****************************************************************************/

/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
//input
	.clk (clk),
	.rst (rst),
	.load (load_ir),
	.in (mdrreg_out),
	//output 
	.funct3 (funct3),
	.funct7 (funct7),
	.opcode (opcode),
	.i_imm (my_i_imm),
	.s_imm (my_s_imm),
	.b_imm (my_b_imm),
	.u_imm (my_u_imm),
	.j_imm (my_j_imm),
	.rs1 (rs1),
	.rs2 (rs2),
	.rd (rd)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);
//assign rs1_out = 32'b0;
//assign rs2_out = 32'b0;

//
regfile regfile (
// input
	 .clk (clk),
	 .rst (rst),
	 .load (load_regfile),
	 .in (regfilemux_out),
	 .src_a (rs1),
	 .src_b (rs2),
	 .dest (rd),
// output
	 .reg_a (rs1_out),
	 .reg_b (rs2_out)
);

pc_register my_pc (
//input
	 .clk (clk),
	 .rst (rst),
	 .load (load_pc),
	 .in (pcmux_out),
//output
	 .out (pc_out)
);

register MAR (
//input
	 .clk (clk),
	 .rst (rst),
	 .load (load_mar),
	 .in (MARmux_out),
//output
	 .out (MAR_out)	 
);

register mem_data_out (
//input
	 .clk (clk),
	 .rst (rst),
	 .load (load_data_out),	 
	 .in (rs2_out),
//output
	 .out (temp_mem_wdata)
//	 .out (mem_wdata)
);


/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu my_alu (
	 .aluop (aluop),
	 .a (alumux1_out),
	 .b (alumux2_out),
	 .f (alu_out)
);
cmp my_cmp (
	 .cmpop (cmpop),
	 .a (rs1_out),
	 .b (cmpmux_out),
	 .f (br_en)
);

/*****************************************************************************/
/******************************* function for lb, lbu,l h, lhu *********************************/
function bit [31:0] lb_funct(input logic [3:0] rmask, logic [31:0] mdrreg_out);
	unique case(rmask)
		4'b0001:
			return {{24{mdrreg_out[7]}},mdrreg_out[7:0]};
		4'b0010:
			return {{24{mdrreg_out[15]}},mdrreg_out[15:8]};
		4'b0100:
			return {{24{mdrreg_out[23]}},mdrreg_out[23:16]};
		4'b1000:
			return {{24{mdrreg_out[31]}},mdrreg_out[31:24]};
		default:
			return {{24{mdrreg_out[7]}},mdrreg_out[7:0]};
		
	endcase
endfunction

function bit [31:0] lbu_funct(input logic [3:0] rmask, logic [31:0] mdrreg_out);
	unique case(rmask)
		4'b0001:
			return {24'b0,mdrreg_out[7:0]};
		4'b0010:
			return {24'b0,mdrreg_out[15:8]};
		4'b0100:
			return {24'b0,mdrreg_out[23:16]};
		4'b1000:
			return {24'b0,mdrreg_out[31:24]};
		default:
			return {24'b0,mdrreg_out[7:0]};
		
	endcase
endfunction

//function bit [31:0] lh_funct(input logic [3:0] rmask, logic [31:0] mdrreg_out);
//	unique case(rmask)
//		4'b0001:
//			return {{16{mdrreg_out[15]}},mdrreg_out[15:0]};
//		4'b0010:
//			return {{16{mdrreg_out[23]}},mdrreg_out[23:8]};
//		4'b0100:
//			return {{16{mdrreg_out[31]}},mdrreg_out[31:16]};
//		default:
//			return {{16{mdrreg_out[15]}},mdrreg_out[15:0]};
//		
//	endcase
//endfunction



function bit [31:0] lh_funct(input logic [1:0] rmask, logic [31:0] mdrreg_out);
	unique case(rmask)
		2'b00:
			return {{16{mdrreg_out[15]}},mdrreg_out[15:0]};
		2'b01:
			return {{16{mdrreg_out[23]}},mdrreg_out[23:8]};
		2'b10:
			return {{16{mdrreg_out[31]}},mdrreg_out[31:16]};
		default:
			return {{16{mdrreg_out[15]}},mdrreg_out[15:0]};
		
	endcase
endfunction

function bit [31:0] lhu_funct(input logic [3:0] rmask, logic [31:0] mdrreg_out);
	unique case(rmask)
		4'b0011:
			return {16'b0,mdrreg_out[15:0]};
		4'b0110:
			return {16'b0,mdrreg_out[23:8]};
		4'b1100:
			return {16'b0,mdrreg_out[31:16]};

		default:
			return {16'b0,mdrreg_out[15:0]};
		
	endcase
endfunction


/*****************************************************************************/
///******************************* CMP definition *********************************/
//

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
	 unique case (MAR_out[1:0])
		  2'b00: mem_wdata = temp_mem_wdata;
		  2'b01: mem_wdata = {temp_mem_wdata[23:0],8'b0};
		  2'b10: mem_wdata = {temp_mem_wdata[15:0],16'b0};
		  2'b11: mem_wdata = {temp_mem_wdata[7:0],24'b0};
		  
		  default: mem_wdata = temp_mem_wdata;
	 
	 endcase
	 
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
		  pcmux::alu_out: pcmux_out = alu_out;
		  pcmux::alu_mod2: pcmux_out = {alu_out[31:1],1'b0}; // anyhow write so that no error

        // etc.
        default: `BAD_MUX_SEL;
    endcase
	 
	 unique case (marmux_sel)
		  marmux::pc_out: MARmux_out = pc_out;
		  marmux::alu_out: MARmux_out = alu_out;
		  default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (cmpmux_sel)
		  cmpmux::rs2_out: cmpmux_out = rs2_out;
		  cmpmux::i_imm: cmpmux_out = my_i_imm;
		  default: `BAD_MUX_SEL;
	 endcase 
	 
	 unique case (alumux1_sel)
		  alumux::rs1_out: alumux1_out = rs1_out;
		  alumux::pc_out: alumux1_out = pc_out;
		  default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (alumux2_sel)
		  alumux::i_imm : alumux2_out = my_i_imm;
		  alumux::u_imm : alumux2_out = my_u_imm;
		  alumux::b_imm : alumux2_out = my_b_imm;
		  alumux::s_imm : alumux2_out = my_s_imm;
		  alumux::j_imm : alumux2_out = my_j_imm;
		  alumux::rs2_out : alumux2_out = rs2_out;
		  default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (regfilemux_sel)
		  regfilemux::alu_out : regfilemux_out = alu_out;
		  regfilemux::br_en : regfilemux_out = {31'b0,br_en};
		  regfilemux::u_imm : regfilemux_out = my_u_imm;
		  regfilemux::lw : regfilemux_out = mdrreg_out; //guess from diagram
		  regfilemux::pc_plus4 : regfilemux_out = pc_out + 4;// how is this different from on top
		  regfilemux::lb : regfilemux_out = lb_funct(rmask_for_datapath,mdrreg_out); //anyhow write one
		  regfilemux::lbu : regfilemux_out = lbu_funct(rmask_for_datapath,mdrreg_out); //anyhow write one
		  regfilemux::lh : regfilemux_out = lh_funct(control_bits_for_mem_address,mdrreg_out); //anyhow write one
//		  regfilemux::lh : regfilemux_out = {{24{mdrreg_out[15]}},mdrreg_out[15:0]};
		  regfilemux::lhu : regfilemux_out = lhu_funct(rmask_for_datapath,mdrreg_out); //anyhow write one
		  default: `BAD_MUX_SEL;
	 endcase
	 
end


/*****************************************************************************/
endmodule : datapath
