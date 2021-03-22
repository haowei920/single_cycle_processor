import rv32i_types::*;

module cmp
(
    input branch_funct3_t cmpop,
    input [31:0] a, b,
    output logic f
);

always_comb
begin
    unique case (cmpop)
        beq:   f = (a==b);
		  bne:   f = (a!=b);
		  blt:   f = ($signed(a)< $signed(b));
		  bge:   f = ($signed(a)>=$signed(b));
		  bltu:   f = (a<b);
		  bgeu:   f = (a>=b);
		  // how to read them as signed or unsigned

    endcase
end

endmodule : cmp
