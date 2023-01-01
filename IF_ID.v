module IF_ID (
    clk_i, rst_i, flush_i, stall_i, 
    inst_i, PC_i,
    inst_o, PC_o
);
input         clk_i, rst_i, flush_i, stall_i;
input  [31:0] inst_i, PC_i;
output reg [31:0] inst_o, PC_o;

// TODO 

endmodule
