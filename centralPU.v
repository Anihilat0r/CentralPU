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
	
  	initial we_alu = 0;
  
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


module mem #(
    parameter INSTR_SIZE,
    parameter DATA_SIZE,
    parameter PROGRAM_SIZE,
    parameter ADDR_SIZE 
) (
    output reg [INSTR_SIZE-1:0] out_data,
    input [ADDR_SIZE-1:0] current_addr,
    input write_en,
  	input execute,
    input [DATA_SIZE-1:0] in_data,
    input clk
);
	
  	reg [INSTR_SIZE-1:0] internal_mem [2**ADDR_SIZE-1:0];

    always @(posedge clk) begin

        //Write to the memory address specified only on the execute cycle
        if (write_en & execute)
            internal_mem[current_addr] [DATA_SIZE-1:0] <= in_data;
    end

    assign out_data = internal_mem[current_addr];  
endmodule


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

