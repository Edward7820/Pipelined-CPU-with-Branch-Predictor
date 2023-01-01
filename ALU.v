`define ADD 3'b000
`define SLL 3'b001
`define SUB 3'b010
`define MUL 3'b011
`define XOR 3'b100
`define SRA 3'b101
`define AND 3'b111

module ALU
(
    data1_i,
    data2_i,
    ALUCtrl_i,
    data_o,
    Zero_o
);

    input[31:0] data1_i;
    input[31:0] data2_i;
    input[2:0] ALUCtrl_i;
    output[31:0] data_o;
    output Zero_o;

    reg[31:0] data_reg;
    reg Zero_reg;

    always@(*)
    begin
        case (ALUCtrl_i)
            `ADD: data_reg = data1_i + data2_i;
            `SUB: data_reg = data1_i - data2_i;
            `MUL: data_reg = data1_i * data2_i;
            `AND: data_reg = data1_i & data2_i;
            `XOR: data_reg = data1_i ^ data2_i;
            `SLL: data_reg = data1_i << data2_i;
            `SRA: data_reg = data1_i >>> data2_i;
        endcase
        if (ALUCtrl_i == `SUB) begin
            if (data1_i - data2_i == 0) begin
                Zero_reg <= 1;
            end
            else begin
                Zero_reg <= 0;
            end
        end
        else begin
            Zero_reg <= 0;
        end
    end
    assign data_o = data_reg;
    assign Zero_o = Zero_reg;

endmodule