module alu #(
    parameter DATA_SIZE,
    parameter OPCODE_SIZE,
    parameter INSTR_SIZE
) (
    output reg signed [DATA_SIZE-1:0] alu_out,
    output reg we_alu,
    input signed [DATA_SIZE-1:0] from_mem_data,
    input signed [DATA_SIZE-1:0] accumulator,
    input [INSTR_SIZE-1:0] instr_reg
);
  
    always @(*) begin

        case (instr_reg[INSTR_SIZE-1:INSTR_SIZE-OPCODE_SIZE]) 
            4'b0001 : begin 
                we_alu = 1'b0;
                alu_out = from_mem_data;
            end
            4'b0010 : begin
                we_alu = 1'b0; 
                alu_out = accumulator + from_mem_data;
            end
            4'b0011 : begin
                we_alu = 1'b0;
                alu_out = accumulator + (~from_mem_data + 1'b1);
            end
            4'b0100 : begin
                we_alu = 1'b0;
                alu_out = accumulator & from_mem_data;
            end
            4'b0101 : begin
                we_alu = 1'b0;
                alu_out = accumulator | from_mem_data;
            end
            4'b0110 : begin
                we_alu = 1'b0;
                alu_out = accumulator ^ from_mem_data;
            end
            4'b0111 : begin
                we_alu = 1'b0;
                alu_out = ~accumulator;
            end
            4'b1000 : begin
                we_alu = 1'b0;
                alu_out = accumulator >> 1;
            end
            4'b1001 : begin
                we_alu = 1'b0;
                alu_out = accumulator << 1;
            end
            4'b1010 : begin
                we_alu = 1'b0;
                alu_out = instr_reg[DATA_SIZE-1:0];
            end
            4'b1011 : begin
                we_alu = 1'b0;
                alu_out = accumulator + instr_reg[DATA_SIZE-1:0];
            end
            4'b1100 : begin
                we_alu = 1'b1;
                alu_out = accumulator;
            end
            default : begin
                we_alu = 1'b0;
                alu_out = accumulator;
            end
        endcase 
    end
endmodule
