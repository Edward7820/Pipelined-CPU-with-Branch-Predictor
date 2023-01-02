module branch_predictor
(
    clk_i, 
    rst_i,

    update_i,
	result_i,
	predict_o
);
    input clk_i, rst_i, update_i, result_i;
    output predict_o;

    reg[1:0] predict_reg; 
    //00: stronly not taken; 01: weakly not taken; 10: weakly taken; 11: strongly taken
    always@(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            predict_reg <= 2'b11;
        end  
        else begin
            if (update_i) begin
                if (result_i) begin
                    if (predict_reg==2'b00) begin
                        predict_reg <= 2'b01;
                    end
                    else if (predict_reg==2'b01) begin
                        predict_reg <= 2'b10;
                    end
                    else if (predict_reg==2'b10) begin
                        predict_reg <= 2'b11;
                    end
                end
                else begin
                    if (predict_reg==2'b11) begin
                        predict_reg <= 2'b10;
                    end
                    else if (predict_reg==2'b10) begin
                        predict_reg <= 2'b01;
                    end
                    else if (predict_reg==2'b01) begin
                        predict_reg <= 2'b00;
                    end
                end
            end
        end
    end

    assign predict_o = predict_reg[1];

endmodule
