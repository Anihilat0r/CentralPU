`include "mem.v"
`include "alu.v"

module central #(
    parameter INSTR_SIZE,
    parameter DATA_SIZE,
    parameter OPCODE_SIZE,
    parameter ADDR_SIZE,
    parameter PROGRAM_SIZE
) (
    output reg out_of_bounds,
    input clk
    //input [INSTR_SIZE-1:0] program_in [PROGRAM_SIZE-1:0]
);
    //Number of bits needed to access program instructions
    parameter PROGRAM_ADDR_SIZE = $clog2(PROGRAM_SIZE);
    
    wire [INSTR_SIZE-1:0] from_mem_data;
    wire [ADDR_SIZE-1:0] current_addr;
    reg [ADDR_SIZE-1:0] generated_addr;
    
    reg [INSTR_SIZE-1:0] instr_reg;
    //Variables that handle arithmetic data
    wire signed [DATA_SIZE-1:0] alu_out;
    reg signed [DATA_SIZE-1:0] accumulator;
    reg signed [PROGRAM_ADDR_SIZE:0] progr_count;
    //Control signals
    wire we_alu;
    reg fetch, execute;
    //PC is used to reference the addresses where the program is stored,
    //so in order to drive the current_addr register correctly padding with 0s may be needed. 
    parameter filler_bits = ADDR_SIZE-PROGRAM_ADDR_SIZE;
    reg [filler_bits-1:0] f_b = 0;

    mem #(
        .ADDR_SIZE(ADDR_SIZE),
        .PROGRAM_SIZE(PROGRAM_SIZE),
        .DATA_SIZE(DATA_SIZE),
        .INSTR_SIZE(INSTR_SIZE)
    ) 
    mem0 (
        .out_data(from_mem_data),
        .current_addr(current_addr),
        .write_en(we_alu),
        .execute(execute),
        .in_data(accumulator),
        .clk(clk)
    );

    alu #(
        .INSTR_SIZE(INSTR_SIZE),
        .DATA_SIZE(DATA_SIZE),
        .OPCODE_SIZE(OPCODE_SIZE)
    )
    alu0 (
        .alu_out(alu_out),
        .we_alu(we_alu),
        .from_mem_data(from_mem_data[DATA_SIZE-1:0]),
        .accumulator(accumulator),
        .instr_reg(instr_reg)
    );

    initial begin
        fetch = 1;
        execute = 0;
        progr_count = 0;
    end

    //Drive the address memory writes/reads
    //When in "fetch" cycle this address is driven by the program counter
    //When in "execute" cycle the address is driven by the appropriate instruction register LSBs
    always @(*) begin
	    
        if (fetch) 
            generated_addr = {f_b, progr_count[PROGRAM_ADDR_SIZE-1:0]};
        else if (execute)
            generated_addr = instr_reg[ADDR_SIZE-1:0];
        else
            generated_addr = 5'b0;
    end
    assign current_addr = generated_addr;


    always @(posedge clk) begin
        //Fetch cycle for loading the next instruction from memory to the instruction register
        if (fetch) begin
            instr_reg <= from_mem_data; 
            fetch <= 1'b0;
            execute <= 1'b1;
        end

        //Execute cycle for passing the result of the current instrustion to the appropriate register
        if (execute) begin
            accumulator <= alu_out;
            //PC can only take address values that correspond to program lines,
            //it can't access the rest of the memory.
            //That's why PROGRAM_ADDR_SIZE is used
            case (instr_reg[INSTR_SIZE-1:INSTR_SIZE-OPCODE_SIZE]) 
                4'b1101 : begin
                    if (accumulator == 0) 
                        progr_count <= progr_count + $signed(instr_reg[PROGRAM_ADDR_SIZE:0]);
                    else 
                        progr_count <= progr_count + 1;
                end
                4'b1110 : begin
                    if (accumulator < 0) 
                        progr_count <= progr_count + $signed(instr_reg[PROGRAM_ADDR_SIZE:0]);
                    else 
                        progr_count <= progr_count + 1;
                end
                4'b1111 : progr_count <= {1'b0, accumulator[PROGRAM_ADDR_SIZE-1:0]};
                default : progr_count <= progr_count + 1;
            endcase
		
            fetch <= 1'b1;
            execute <= 1'b0; 
        end
    end
    
    //Signifies that the program execution has ended
    //Gets set only at power of 2 program counter values (not exactly when the program has concluded its run)
    assign out_of_bounds = progr_count[PROGRAM_ADDR_SIZE];
endmodule
