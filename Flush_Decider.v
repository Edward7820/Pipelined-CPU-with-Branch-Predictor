module flush_decider
(
    zero_i,
    predict_i,
    branch_i,
    IF_flush_o,
    ID_flush_o
);
    input zero_i, predict_i, branch_i;
    //zero_i: whether branch should be taken
    //predict_i: whether branch is predicted to be taken
    //branch_i: whether current instruction is a branch instruction
    output IF_flush_o; //whether to flush IF/ID register
    output ID_flush_o; //whether to flush ID/EX register

    reg IF_flush_reg;
    reg ID_flush_reg;

    assign IF_flush_o = IF_flush_reg;
    assign ID_flush_o = ID_flush_reg;

    if (branch_i) begin
        if (zero_i and predict_i) begin
            ID_flush_reg <= 1'b1;
            IF_flush_reg <= 1'b0;
        end
    end

endmodule