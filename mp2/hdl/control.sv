
import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rst,
/********************datapath to control signals******************************/
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
	 input rv32i_word mem_address_to_datapath,
/*****************************************************************************/

/********************memory to control signals******************************/
	 input mem_resp,
/*****************************************************************************/
/********************control to datapath signals******************************/

    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
	 output branch_funct3_t cmpop, //how to get this
	 output logic [3:0] rmask_for_datapath,
/*****************************************************************************/
	 
/********************control to memory signals******************************/
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable

);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
					 lh, lhu:
					 begin 
					 rmask = (4'b0011 << mem_address_to_datapath[1:0]) /* Modify for MP1 Final */ ;
//					 rmask = 4'bXXXX /* Modify for MP1 Final */ ;
					 end
					 lb, lbu: rmask = (4'b0001 << mem_address_to_datapath[1:0])/* Modify for MP1 Final */ ;
					 
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
//                sh: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
					 sh: wmask = (4'b0011 << mem_address_to_datapath[1:0]);
//                sb: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
					 sb: wmask = (4'b0001 << mem_address_to_datapath[1:0]);
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
	 fetch1, fetch2, fetch3, decode, s_imm, br, calc_addr_st, calc_addr_ld, ldr1, ldr2, str1, str2, s_auipc, s_lui, jal, jalr, s_reg
} state, next_states;

int unsigned state_debug;
assign state_debug = state;
//logic rmask_for_datapath;
assign rmask_for_datapath = rmask;
/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();

	load_pc = 1'b0;
	load_ir = 1'b0;
	load_regfile = 1'b0;
	load_mar = 1'b0;
	load_mdr = 1'b0;
	load_data_out = 1'b0;
	pcmux_sel = pcmux::pc_plus4;
	cmpop = branch_funct3_t'(funct3);
	alumux1_sel = alumux::rs1_out;
	alumux2_sel = alumux::i_imm;
	regfilemux_sel = regfilemux::alu_out;
	marmux_sel = marmux::pc_out;
	cmpmux_sel = cmpmux::rs2_out;
	aluop = alu_ops'(funct3);
	mem_read = 1'b0;
	mem_write = 1'b0;
	mem_byte_enable = 4'b1111;
//	rs1 = 5'b0;
//	rs2 = 5'b0;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	 load_regfile = 1'b1;
	 regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
	 load_mar = 1'b1;
	 marmux_sel = sel;
endfunction

function void loadMDR();
	 load_mdr = 1'b1;
endfunction

function void loadIR();
	load_ir = 1'b1;
endfunction

function void loadDataOut();
	load_data_out = 1'b1;
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */
	 alumux1_sel = sel1;
	 alumux2_sel = sel2;

    if (setop)
        aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
	cmpmux_sel = sel;
	cmpop = op;
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	 
	 case (state)
			fetch1: 
				loadMAR(marmux::pc_out);
				
			fetch2:
			begin
				loadMDR();
				mem_read = 1'b1;
			end
			
			fetch3: 
				loadIR();
				
			s_lui:
			begin
				loadPC(pcmux::pc_plus4);
				loadRegfile(regfilemux::u_imm);
				// what is rs1_addr <- rs1
			end
			
			s_auipc:
			begin
				loadPC(pcmux::pc_plus4);
				loadRegfile(regfilemux::alu_out);
				setALU(alumux::pc_out,alumux::u_imm,1'b1,alu_add);

			end
			
			br:
			begin
				loadPC(pcmux::pcmux_sel_t'(br_en));
				setALU(alumux::pc_out,alumux::b_imm,1'b1,alu_add);
				// what happened to rs1_addr <- rs1;
			end
			
			s_imm:
			begin
//				loadPC(pcmux::pc_plus4);
//				loadRegfile(regfilemux::alu_out);
//				setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_ops'(funct3));

			begin
				unique case (arith_funct3)
					slt:
					begin
						loadPC(pcmux::pc_plus4);
						loadRegfile(regfilemux::br_en);
						setCMP(cmpmux::i_imm,branch_funct3_t'(blt));

					end
					
					sltu:
					begin
						loadPC(pcmux::pc_plus4);
						loadRegfile(regfilemux::br_en);
						setCMP(cmpmux::i_imm,branch_funct3_t'(bltu));
						
					end
					
					sr:
					begin
						if (funct7 == 7'b0100000)
						begin
							loadPC(pcmux::pc_plus4);
							loadRegfile(regfilemux::alu_out);
							setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_sra);
						end
						else
						begin
							loadPC(pcmux::pc_plus4);
							loadRegfile(regfilemux::alu_out);
							setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_ops'(funct3));
							
						end
					end
					default:
					begin
						loadPC(pcmux::pc_plus4);
						loadRegfile(regfilemux::alu_out);
						setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_ops'(funct3));
					end
				endcase


			end				
				
			end
			
			calc_addr_ld:
			begin
				loadMAR(marmux::alu_out);
				setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_add);
			end
			
			ldr1:
			begin
				loadMDR();
				mem_read = 1'b1;
			end
			
			ldr2:
			begin
				loadPC(pcmux::pc_plus4);
				// this is currently for full word
				unique case (load_funct3)
					lb:
					begin
						loadRegfile(regfilemux::lb);
					end
					
					lbu:
					begin
						loadRegfile(regfilemux::lbu);
					end
					
					lh:
					begin
						loadRegfile(regfilemux::lh);

					end
					
					lhu:
					begin
						loadRegfile(regfilemux::lhu);

					end
					
					default:
					begin
						loadRegfile(regfilemux::lw);
					end
				endcase
			end
			
			calc_addr_st:
			begin
				loadMAR(marmux::alu_out);
				setALU(alumux::rs1_out,alumux::s_imm,1'b1,alu_add);
				loadDataOut();
			end
			
			str1:
			begin
				mem_write = 1'b1;
				unique case(store_funct3)
					sb:
						mem_byte_enable = wmask;
					sh:
						mem_byte_enable = wmask;
					default:
						mem_byte_enable = (4'b1111);
				endcase
				
			end
			
			str2:
			begin
				loadPC(pcmux::pc_plus4);
			end
			
			jal:
			begin
				loadPC(pcmux::alu_mod2);
				setALU(alumux::pc_out,alumux::j_imm,1'b1,alu_add);
				loadRegfile(regfilemux::pc_plus4);
			end
			
			jalr:
			begin
				loadPC(pcmux::alu_mod2);
				setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_add);
				loadRegfile(regfilemux::pc_plus4);
			end
			
			s_reg:
			begin
				unique case (arith_funct3)
				
					slt:
					begin
						loadPC(pcmux::pc_plus4);
						loadRegfile(regfilemux::br_en);
						setCMP(cmpmux::rs2_out,branch_funct3_t'(blt));

					end
					
					sltu:
					begin
						loadPC(pcmux::pc_plus4);
						loadRegfile(regfilemux::br_en);
						setCMP(cmpmux::rs2_out,branch_funct3_t'(bltu));

					end
					
					sr:
					begin
						if (funct7 == 7'b0100000)
						begin
							loadPC(pcmux::pc_plus4);
							loadRegfile(regfilemux::alu_out);
							setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_sra);
						end
						else
						begin
							loadPC(pcmux::pc_plus4);
							loadRegfile(regfilemux::alu_out);
							setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_ops'(funct3));
							
						end
					end
				
					add:
					begin
						if (funct7 == 7'b0100000)
						begin
							loadPC(pcmux::pc_plus4);
							loadRegfile(regfilemux::alu_out);
							setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_sub);
						end
						else
						begin
							loadPC(pcmux::pc_plus4);
							loadRegfile(regfilemux::alu_out);
							setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_ops'(funct3));
							
						end
						
					end
					default:
					begin
						loadPC(pcmux::pc_plus4);
						setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_ops'(funct3));
						loadRegfile(regfilemux::alu_out);
					end
				endcase
			end
			
			
			
			
			default: ;
	 endcase
	 
	 
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  next_states = state;
	  
	  unique case (state)
			fetch1: 
				next_states = fetch2;
			
			fetch2:
			begin
				if (mem_resp)
					next_states = fetch3;
				else
					next_states = fetch2;
			end
			
			fetch3:
				next_states = decode;
				
			decode:
				case (opcode)
						op_lui: next_states = s_lui;
						op_auipc: next_states = s_auipc;
						op_jal: next_states = jal;
						op_jalr: next_states = jalr;
						op_br: next_states = br;
						op_load: next_states = calc_addr_ld;
						op_store: next_states = calc_addr_st;
						op_imm: next_states = s_imm;
						op_reg: next_states = s_reg;
//						op_csr: 
						default: next_states = fetch1;
				endcase
				
			s_reg:
				next_states = fetch1;

				
			jal:
				next_states = fetch1;
			
			jalr:
				next_states = fetch1;

				
			s_lui:
				next_states = fetch1;
				
			s_auipc:
				next_states = fetch1;
				
			br:
				next_states = fetch1;
				
			s_imm:
				next_states = fetch1;
			
			calc_addr_ld:
				next_states = ldr1;
				
			ldr1:
			begin
				if (mem_resp)
					next_states = ldr2;
				else
					next_states = ldr1;
			end
			
			calc_addr_st:
				next_states = str1;
			
			str1:
			begin
				if (mem_resp)
					next_states = str2;
				else
					next_states = str1;
			end
			
			str2:
				next_states = fetch1;
				
			ldr2:
				next_states = fetch1;
				
	  endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 if (rst)
		state <= fetch1;
	 else
		state <= next_states;
end

endmodule : control


