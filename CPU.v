module CPU
(
    clk_i,
    rst_i,
);

    // Ports
    input clk_i;
    input rst_i;

    //global wire
    wire[31:0] four;
    assign four = 32'd4;

    //IF stage
    wire[31:0] IF_next_pc;
    wire[31:0] IF_next_pc_without_rolling_back;
    wire[31:0] IF_pc_plus_four;
    wire[31:0] IF_pc;
    wire pc_write;
    wire[31:0] IF_instruction;

    //ID stage
    wire IF_Flush;
    wire IF_Flush_by_predictor;
    wire IF_Flush_by_ALU;
    assign IF_Flush = IF_Flush_by_ALU | IF_Flush_by_predictor;
    wire[31:0] ID_instruction;
    wire[2:0] ID_ALUOp;
    wire ID_ALUSrc;
    wire ID_MemWrite;
    wire ID_MemRead;
    wire ID_MemtoReg;
    wire ID_RegWrite;
    wire[31:0] ID_rs1data;
    wire[31:0] ID_rs2data;
    wire[31:0] ID_Imm;
    wire ID_predict;
    wire ID_Branch_Control;
    wire NoOp;
    wire Stall;
    wire[31:0] ID_pc;
    wire[31:0] ID_Branch_pc;
    wire[31:0] ID_Imm_2; //ID_Imm * 2

    //EX Stage
    wire ID_Flush;
    wire[31:0] EX_instruction;
    wire[2:0] EX_ALUOp;
    wire EX_ALUSrc;
    wire EX_MemWrite;
    wire EX_MemRead;
    wire EX_MemtoReg;
    wire EX_RegWrite;
    wire[31:0] EX_rs1data;
    wire[31:0] EX_rs2data;
    wire[31:0] EX_Imm;
    wire[31:0] EX_Imm_2;
    wire[1:0] ForwardA;
    wire[1:0] ForwardB;
    wire[31:0] srcdata1; //after forwarding
    wire[31:0] srcdata2; //after forwarding
    wire[31:0] EX_memwritedata; //after forwarding
    wire[31:0] ALUsrcdata1;
    wire[31:0] ALUsrcdata2;
    wire[31:0] EX_ALUresult;
    wire EX_Zero;
    wire EX_predict;
    wire EX_Branch_Control;
    wire[31:0] EX_pc;
    wire[31:0] EX_next_pc;

    //MEM stage
    wire[31:0] MEM_ALUresult;
    wire[31:0] MEM_memwritedata;
    wire[4:0] MEM_rdaddr;
    wire MEM_MemRead;
    wire MEM_MemWrite;
    wire MEM_RegWrite;
    wire MEM_MemtoReg;
    wire[31:0] MEM_memreaddata;

    //WB stage
    wire[31:0] WB_memreaddata;
    wire[31:0] WB_ALUresult;
    wire[4:0] WB_rdaddr;
    wire WB_RegWrite;
    wire WB_MemtoReg;
    wire[31:0] WB_writedata;

    //IF stage
    MUX2 Select_pc_source1(
        .data1_i(IF_pc_plus_four),
        .data2_i(ID_Branch_pc),
        .select_i(IF_Flush_by_predictor),
        .data_o(IF_next_pc_without_rolling_back)
    );

    MUX2 Select_pc_source2(
        .data1_i(IF_next_pc_without_rolling_back),
        .data2_i(EX_next_pc),
        .select_i(IF_Flush_by_ALU),
        .data_o(IF_next_pc)
    );

    PC PC(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .PCWrite_i(pc_write),
        .pc_i(IF_next_pc),
        .pc_o(IF_pc)
    );

    Adder IF_Add_PC(
        .data1_in(IF_pc),
        .data2_in(four),
        .data_o(IF_pc_plus_four)
    );

    Instruction_Memory Instruction_Memory(
        .addr_i(IF_pc),
        .instr_o(IF_instruction)
    );

    //ID stage
    IFIDRegisters IFIDRegisters(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .Op_i(IF_instruction),
        .Stall_i(Stall),
        .Flush_i(IF_Flush),
        .pc_i(IF_pc),
        .Op_o(ID_instruction),
        .pc_o(ID_pc)
    );

    Control Control(
        .Op_i(ID_instruction),
        .NoOp_i(NoOp),
        .ALUOp_o(ID_ALUOp),
        .ALUSrc_o(ID_ALUSrc),
        .RegWrite_o(ID_RegWrite),
        .MemtoReg_o(ID_MemtoReg),
        .MemRead_o(ID_MemRead),
        .MemWrite_o(ID_MemWrite),
        .Branch_o(ID_Branch_Control)
    );

    HazardDetectionUnit HazardDetectionUnit(
        .MemRead_i(EX_MemRead),
        .ALUSrc_i(ID_ALUSrc),
        .RDaddr_i(EX_instruction[11:7]),
        .RS1addr_i(ID_instruction[19:15]),
        .RS2addr_i(ID_instruction[24:20]),
        .PCWrite_o(pc_write),
        .Stall_o(Stall),
        .NoOp_o(NoOp)
    );

    Registers Registers(
        .clk_i(clk_i),
        .RS1addr_i(ID_instruction[19:15]),
        .RS2addr_i(ID_instruction[24:20]),
        .RDaddr_i(WB_rdaddr), 
        .RDdata_i(WB_writedata),
        .RegWrite_i(WB_RegWrite), 
        .RS1data_o(ID_rs1data), 
        .RS2data_o(ID_rs2data) 
    );

    branch_predictor branch_predictor
    (
        .clk_i(clk_i), 
        .rst_i(rst_i),
        .update_i(EX_Branch_Control),
        .result_i(EX_Zero),
        .predict_o(ID_predict)
    );

    AndGate AndGate(
        .input1_i(ID_Branch_Control),
        .input2_i(ID_predict),
        .output_o(IF_Flush_by_predictor)
    );

    ImmGen ImmGen(
        .Op_i(ID_instruction),
        .Imm_o(ID_Imm)
    );

    LeftShift ID_LeftShift(
        .data_i(ID_Imm),
        .data_o(ID_Imm_2)
    );

    Adder ID_Calculate_Branch_pc(
        .data1_in(ID_Imm_2),
        .data2_in(ID_pc),
        .data_o(ID_Branch_pc)
    );

    //EX_stage
    IDEXRegisters IDEXRegisters(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .Flush_i(ID_Flush),
        .RegWrite_i(ID_RegWrite),
        .MemtoReg_i(ID_MemtoReg),
        .MemRead_i(ID_MemRead),
        .MemWrite_i(ID_MemWrite),
        .ALUOp_i(ID_ALUOp),
        .ALUSrc_i(ID_ALUSrc),
        .RS1data_i(ID_rs1data),
        .RS2data_i(ID_rs2data),
        .Imm_i(ID_Imm),
        .Op_i(ID_instruction),
        .Branch_i(ID_Branch_Control),
        .Predict_i(ID_predict),
        .PC_i(ID_pc),
        .ALUOp_o(EX_ALUOp),
        .ALUSrc_o(EX_ALUSrc),
        .RegWrite_o(EX_RegWrite),
        .MemtoReg_o(EX_MemtoReg),
        .MemRead_o(EX_MemRead),
        .MemWrite_o(EX_MemWrite),
        .RS1data_o(EX_rs1data),
        .RS2data_o(EX_rs2data),
        .Imm_o(EX_Imm),
        .Op_o(EX_instruction),
        .Branch_o(EX_Branch_Control),
        .Predict_o(EX_predict),
        .PC_o(EX_pc)
    );

    LeftShift EX_LeftShift(
        .data_i(EX_Imm),
        .data_o(EX_Imm_2)
    );

    EX_generate_next_pc EX_generate_next_pc(
        .pc_i(EX_pc),
        .imm_i(EX_Imm_2),
        .zero_i(EX_Zero),
        .pc_o(EX_next_pc)
    );

    ForwardingUnit ForwardingUnit(
        .EXrs1_i(EX_instruction[19:15]),
        .EXrs2_i(EX_instruction[24:20]),
        .MEMRegWrite_i(MEM_RegWrite),
        .MEMrd_i(MEM_rdaddr),
        .WBRegWrite_i(WB_RegWrite),
        .WBrd_i(WB_rdaddr),
        .ForwardA_o(ForwardA),
        .ForwardB_o(ForwardB)
    );

    wire[31:0] tmp;
    assign tmp = 32'd0;

    MUX4 MUXA(
        .data1_i(EX_rs1data),
        .data2_i(WB_writedata),
        .data3_i(MEM_ALUresult),
        .data4_i(tmp),
        .select_i(ForwardA),
        .data_o(srcdata1)
    );

    MUX4 MUXB(
        .data1_i(EX_rs2data),
        .data2_i(WB_writedata),
        .data3_i(MEM_ALUresult),
        .data4_i(tmp),
        .select_i(ForwardB),
        .data_o(srcdata2)
    );

    MUX2 MUX_ALUSrc2(
        .data1_i(srcdata2),
        .data2_i(EX_Imm),
        .select_i(EX_ALUSrc),
        .data_o(ALUsrcdata2)
    );

    assign ALUsrcdata1 = srcdata1;
    assign EX_memwritedata = srcdata2;

    ALU ALU(
        .data1_i(ALUsrcdata1),
        .data2_i(ALUsrcdata2),
        .ALUCtrl_i(EX_ALUOp),
        .data_o(EX_ALUresult),
        .Zero_o(EX_Zero)
    );

    flush_decider flush_decider
    (
        .zero_i(EX_Zero),
        .predict_i(EX_predict),
        .branch_i(EX_Branch_Control),
        .IF_flush_o(IF_Flush_by_ALU),
        .ID_flush_o(ID_Flush)
    );

    //MEM stage
    EXMEMRegisters EXMEMRegisters(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .RegWrite_i(EX_RegWrite),
        .MemtoReg_i(EX_MemtoReg),
        .MemRead_i(EX_MemRead),
        .MemWrite_i(EX_MemWrite),
        .ALUResult_i(EX_ALUresult),
        .RS2data_i(EX_memwritedata),
        .RDaddr_i(EX_instruction[11:7]),
        .RegWrite_o(MEM_RegWrite),
        .MemtoReg_o(MEM_MemtoReg),
        .MemRead_o(MEM_MemRead),
        .MemWrite_o(MEM_MemWrite),
        .ALUResult_o(MEM_ALUresult),
        .RS2data_o(MEM_memwritedata),
        .RDaddr_o(MEM_rdaddr)
    );

    Data_Memory Data_Memory(
        .clk_i(clk_i), 
        .addr_i(MEM_ALUresult), 
        .MemRead_i(MEM_MemRead),
        .MemWrite_i(MEM_MemWrite),
        .data_i(MEM_memwritedata),
        .data_o(MEM_memreaddata)
    );

    //WB stage
    MEMWBRegisters MEMWBRegisters(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .RegWrite_i(MEM_RegWrite),
        .MemtoReg_i(MEM_MemtoReg),
        .ALUResult_i(MEM_ALUresult),
        .Memdata_i(MEM_memreaddata),
        .RDaddr_i(MEM_rdaddr),
        .RegWrite_o(WB_RegWrite),
        .MemtoReg_o(WB_MemtoReg),
        .ALUResult_o(WB_ALUresult),
        .Memdata_o(WB_memreaddata),
        .RDaddr_o(WB_rdaddr)
    );

    MUX2 WriteBachDataMUX(
        .data1_i(WB_ALUresult),
        .data2_i(WB_memreaddata),
        .select_i(WB_MemtoReg),
        .data_o(WB_writedata)
    );

endmodule