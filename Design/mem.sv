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
    localparam DATA_OVERHEAD = INSTR_SIZE - DATA_SIZE;
    reg [DATA_OVERHEAD-1:0] d_o = 0;
    reg [INSTR_SIZE-1:0] internal_mem [2**ADDR_SIZE-1:0];  

    //The program can also be loaded using a memory initialization
    //text file (values must be hexadecimal).
    /*
    initial begin
        $display("Initializing memory from mem_init.txt");
        $readmemh("mem_init.txt", internal_mem)
    end
    */

    always @(posedge clk) begin

        //Write to the memory address specified only on the execute cycle
        if (write_en & execute)
          internal_mem[current_addr] [INSTR_SIZE-1:0] <= {d_o, in_data};
    end

    assign out_data = internal_mem[current_addr];  
endmodule
