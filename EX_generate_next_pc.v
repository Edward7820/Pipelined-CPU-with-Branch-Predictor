module EX_generate_next_pc
(
    pc_i,
    imm_i,
    zero_i,
    pc_o
);

    input[31:0] pc_i;
    input[31:0] imm_i;
    input zero_i;
    output[31:0] pc_o;

    reg[31:0] pc_reg;
    assign pc_o = pc_reg;

    always@(*)
    begin
        if (zero_i) begin
            pc_reg <= pc_i + imm_i; 
        end
        else begin
            pc_reg <= pc_i + 32'd4;
        end
    end

endmodule